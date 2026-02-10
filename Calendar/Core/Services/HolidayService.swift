import Foundation
import SwiftData
import WidgetKit

// MARK: - API Response Models

private struct CalendarificResponse: Codable {
  let meta: CalendarificMeta
  let response: CalendarificResponseBody
}

private struct CalendarificMeta: Codable {
  let code: Int
}

private struct CalendarificResponseBody: Codable {
  let holidays: [CalendarificHoliday]?
  let countries: [CalendarificCountry]?
}

struct CalendarificHoliday: Codable {
  let name: String
  let description: String
  let date: HolidayDate
  let type: [String]

  struct HolidayDate: Codable {
    let iso: String
  }
}

struct CalendarificCountry: Codable, Identifiable {
  let countryName: String
  let isoCode: String

  var id: String { isoCode }

  enum CodingKeys: String, CodingKey {
    case countryName = "country_name"
    case isoCode = "iso-3166"
  }
}

// MARK: - Holiday Service

final class HolidayService {
  static let shared = HolidayService()

  private let defaults: UserDefaults
  private let session: URLSession

  private init() {
    defaults = UserDefaults(suiteName: Constants.Storage.appGroupIdentifier) ?? .standard
    session = URLSession.shared
  }

  // MARK: - Public API

  /// Fetch available countries from the Calendarific API.
  /// Results are cached in UserDefaults for offline access.
  func fetchCountries(apiKey: String) async throws -> [CalendarificCountry] {
    let url = URL(
      string: "\(Constants.Holiday.apiBaseURL)/countries?api_key=\(apiKey)")!

    let (data, response) = try await session.data(from: url)
    try validateResponse(response, data: data)

    let decoded = try JSONDecoder().decode(CalendarificResponse.self, from: data)
    guard let countries = decoded.response.countries else {
      throw HolidayError.noData
    }

    // Cache as JSON
    do {
      let cacheData = try JSONEncoder().encode(countries)
      if let cacheString = String(data: cacheData, encoding: .utf8) {
        defaults.set(cacheString, forKey: Constants.Holiday.countriesCacheKey)
      }
    } catch {
      ErrorPresenter.presentOnMain(error)
    }

    return countries.sorted { $0.countryName < $1.countryName }
  }

  /// Load cached countries from UserDefaults (no network).
  func cachedCountries() -> [CalendarificCountry] {
    guard let json = defaults.string(forKey: Constants.Holiday.countriesCacheKey),
      let data = json.data(using: .utf8)
    else { return [] }
    do {
      let countries = try JSONDecoder().decode([CalendarificCountry].self, from: data)
      return countries.sorted { $0.countryName < $1.countryName }
    } catch {
      ErrorPresenter.shared.present(error)
      return []
    }
  }

  /// Fetch holidays for a given country and year.
  func fetchHolidays(apiKey: String, country: String, year: Int) async throws
    -> [CalendarificHoliday]
  {
    var urlString =
      "\(Constants.Holiday.apiBaseURL)/holidays?api_key=\(apiKey)&country=\(country)&year=\(year)"

    // Add language if configured (non-premium may be ignored but won't break)
    if let langCode = defaults.string(forKey: Constants.Holiday.languageCodeKey),
      !langCode.isEmpty
    {
      urlString += "&language=\(langCode)"
    }

    let url = URL(string: urlString)!
    let (data, response) = try await session.data(from: url)
    try validateResponse(response, data: data)

    let decoded = try JSONDecoder().decode(CalendarificResponse.self, from: data)
    guard let holidays = decoded.response.holidays else {
      throw HolidayError.noData
    }

    return holidays
  }

  /// Sync holidays: delete existing holiday events, fetch fresh ones, insert into SwiftData.
  func syncHolidays(context: ModelContext) async throws {
    guard let apiKey = defaults.string(forKey: Constants.Holiday.apiKeyKey),
      !apiKey.isEmpty
    else {
      throw HolidayError.missingApiKey
    }

    guard let countryCode = defaults.string(forKey: Constants.Holiday.countryCodeKey),
      !countryCode.isEmpty
    else {
      throw HolidayError.missingCountry
    }

    let year = Calendar.current.component(.year, from: Date())
    let holidays = try await fetchHolidays(apiKey: apiKey, country: countryCode, year: year)

    // Delete all existing holiday events
    await MainActor.run {
      let descriptor = FetchDescriptor<Event>(
        predicate: #Predicate { $0.isHoliday == true }
      )
      do {
        let existing = try context.fetch(descriptor)
        for event in existing { context.delete(event) }
      } catch {
        ErrorPresenter.shared.present(error)
      }
    }

    // Insert fresh holiday events
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    // Also try ISO8601 with time component
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [
      .withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime,
    ]

    await MainActor.run {
      for holiday in holidays {
        let isoString = holiday.date.iso
        // Try date-only first, then ISO8601 with time
        let parsedDate: Date? =
          dateFormatter.date(from: String(isoString.prefix(10)))
          ?? isoFormatter.date(from: isoString)

        guard let date = parsedDate else { continue }

        let holidayId = "\(countryCode)-\(String(isoString.prefix(10)))-\(holiday.name)"

        let event = Event(
          date: date,
          title: holiday.name,
          notes: holiday.description.isEmpty ? nil : holiday.description,
          color: Constants.Holiday.holidayColor,
          isHoliday: true,
          holidayId: holidayId
        )
        context.insert(event)
      }

      do {
        try context.save()
      } catch {
        ErrorPresenter.shared.present(error)
      }
    }

    // Update last sync date
    defaults.set(Date(), forKey: Constants.Holiday.lastSyncDateKey)

    // Sync to widget
    await MainActor.run {
      EventViewModel().syncEventsToWidget(context: context)
    }
  }

  /// Remove all holiday events (when user selects "None" country).
  func removeAllHolidays(context: ModelContext) async {
    await MainActor.run {
      let descriptor = FetchDescriptor<Event>(
        predicate: #Predicate { $0.isHoliday == true }
      )
      do {
        let existing = try context.fetch(descriptor)
        for event in existing { context.delete(event) }
        try context.save()
        EventViewModel().syncEventsToWidget(context: context)
      } catch {
        ErrorPresenter.shared.present(error)
      }
    }
  }

  /// Check if auto-sync should run (only at the start of a new month).
  func shouldAutoSync() -> Bool {
    guard defaults.string(forKey: Constants.Holiday.apiKeyKey) != nil,
      defaults.string(forKey: Constants.Holiday.countryCodeKey) != nil
    else { return false }

    guard let lastSync = defaults.object(forKey: Constants.Holiday.lastSyncDateKey) as? Date else {
      return false
    }

    let calendar = Calendar.current
    let lastSyncMonth = calendar.component(.month, from: lastSync)
    let lastSyncYear = calendar.component(.year, from: lastSync)
    let currentMonth = calendar.component(.month, from: Date())
    let currentYear = calendar.component(.year, from: Date())

    // Sync if we're in a new month compared to the last sync
    return currentYear > lastSyncYear || currentMonth > lastSyncMonth
  }

  /// Look up language for a country code from the static map.
  func languageForCountry(_ code: String) -> (code: String, name: String)? {
    Constants.Holiday.countryLanguageMap[code.uppercased()]
  }

  // MARK: - Private Helpers

  private func validateResponse(_ response: URLResponse, data: Data) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw HolidayError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      // Try to parse Calendarific error
      if let decoded = try? JSONDecoder().decode(CalendarificResponse.self, from: data) {
        switch decoded.meta.code {
        case 401: throw HolidayError.invalidApiKey
        case 422: throw HolidayError.invalidParameters
        case 429: throw HolidayError.rateLimited
        default: throw HolidayError.apiError(code: decoded.meta.code)
        }
      }
      throw HolidayError.httpError(statusCode: httpResponse.statusCode)
    }
  }
}

// MARK: - Errors

enum HolidayError: LocalizedError {
  case missingApiKey
  case missingCountry
  case invalidApiKey
  case invalidParameters
  case rateLimited
  case invalidResponse
  case noData
  case apiError(code: Int)
  case httpError(statusCode: Int)

  var errorDescription: String? {
    switch self {
    case .missingApiKey: return "API key not configured"
    case .missingCountry: return "Country not selected"
    case .invalidApiKey: return "Invalid API key"
    case .invalidParameters: return "Invalid request parameters"
    case .rateLimited: return "API rate limit exceeded"
    case .invalidResponse: return "Invalid server response"
    case .noData: return "No holiday data returned"
    case .apiError(let code): return "API error (code \(code))"
    case .httpError(let statusCode): return "HTTP error (\(statusCode))"
    }
  }
}
