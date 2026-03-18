import Foundation

enum GoogleCalendarAPIError: LocalizedError {
  case missingTokens
  case expiredTokens
  case invalidURL
  case invalidResponse
  case unauthorized
  case forbidden
  case rateLimited
  case httpError(statusCode: Int, message: String?)
  case decodingFailed

  var errorDescription: String? {
    switch self {
    case .missingTokens:
      return "Google OAuth tokens are missing."
    case .expiredTokens:
      return "Google OAuth tokens have expired."
    case .invalidURL:
      return "Google Calendar API URL is invalid."
    case .invalidResponse:
      return "Google Calendar API returned an invalid response."
    case .unauthorized:
      return "Google Calendar API authorization failed."
    case .forbidden:
      return "Google Calendar API access is forbidden."
    case .rateLimited:
      return "Google Calendar API rate limit reached."
    case .httpError(let statusCode, let message):
      return "Google Calendar API error \(statusCode): \(message ?? "Unknown error")"
    case .decodingFailed:
      return "Failed to decode Google Calendar API response."
    }
  }
}

final class GoogleCalendarAPIClient {
  private let session: URLSession
  private let tokenStore: GoogleTokenStore
  private let jsonDecoder: JSONDecoder
  private let jsonEncoder: JSONEncoder

  init(
    session: URLSession = .shared,
    tokenStore: GoogleTokenStore = GoogleKeychainStore.shared
  ) {
    self.session = session
    self.tokenStore = tokenStore

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.jsonDecoder = decoder

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.jsonEncoder = encoder
  }

  func listCalendars(pageToken: String? = nil) async throws -> GoogleCalendarListResponse {
    var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")
    components?.queryItems = [
      URLQueryItem(name: "showHidden", value: "false"),
      URLQueryItem(name: "minAccessRole", value: "reader"),
    ]

    if let pageToken, !pageToken.isEmpty {
      components?.queryItems?.append(URLQueryItem(name: "pageToken", value: pageToken))
    }

    return try await send(
      method: "GET",
      url: components?.url,
      responseType: GoogleCalendarListResponse.self
    )
  }

  func listEvents(
    calendarId: String,
    syncToken: String? = nil,
    pageToken: String? = nil,
    singleEvents: Bool = true,
    maxResults: Int = 250
  ) async throws -> GoogleEventListResponse {
    let escapedCalendarId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    guard let escapedCalendarId else {
      throw GoogleCalendarAPIError.invalidURL
    }

    var components = URLComponents(
      string: "https://www.googleapis.com/calendar/v3/calendars/\(escapedCalendarId)/events")
    var queryItems = [
      URLQueryItem(name: "singleEvents", value: singleEvents ? "true" : "false"),
      URLQueryItem(name: "showDeleted", value: "true"),
      URLQueryItem(name: "maxResults", value: String(maxResults)),
    ]

    if let syncToken, !syncToken.isEmpty {
      queryItems.append(URLQueryItem(name: "syncToken", value: syncToken))
    }

    if let pageToken, !pageToken.isEmpty {
      queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
    }

    components?.queryItems = queryItems

    return try await send(
      method: "GET",
      url: components?.url,
      responseType: GoogleEventListResponse.self
    )
  }

  func createEvent(calendarId: String, request: GoogleEventUpsertRequest) async throws -> GoogleEventDTO {
    let escapedCalendarId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    guard let escapedCalendarId else {
      throw GoogleCalendarAPIError.invalidURL
    }

    let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(escapedCalendarId)/events")
    let body = try jsonEncoder.encode(request)

    return try await send(method: "POST", url: url, body: body, responseType: GoogleEventDTO.self)
  }

  func patchEvent(
    calendarId: String,
    eventId: String,
    request: GoogleEventUpsertRequest
  ) async throws -> GoogleEventDTO {
    let escapedCalendarId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    let escapedEventId = eventId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    guard let escapedCalendarId, let escapedEventId else {
      throw GoogleCalendarAPIError.invalidURL
    }

    let url = URL(
      string: "https://www.googleapis.com/calendar/v3/calendars/\(escapedCalendarId)/events/\(escapedEventId)")
    let body = try jsonEncoder.encode(request)

    return try await send(method: "PATCH", url: url, body: body, responseType: GoogleEventDTO.self)
  }

  func deleteEvent(calendarId: String, eventId: String) async throws {
    let escapedCalendarId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    let escapedEventId = eventId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    guard let escapedCalendarId, let escapedEventId else {
      throw GoogleCalendarAPIError.invalidURL
    }

    let url = URL(
      string: "https://www.googleapis.com/calendar/v3/calendars/\(escapedCalendarId)/events/\(escapedEventId)")

    _ = try await send(method: "DELETE", url: url, responseType: EmptyGoogleResponse.self)
  }

  private func authorizedRequest(method: String, url: URL, body: Data? = nil) throws -> URLRequest {
    guard var tokens = try tokenStore.loadTokens() else {
      throw GoogleCalendarAPIError.missingTokens
    }

    if tokens.expirationDate <= Date() {
      throw GoogleCalendarAPIError.expiredTokens
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if let body {
      request.httpBody = body
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    // Keep mutable local to make it obvious where refresh logic will be inserted in a later step.
    _ = tokens
    return request
  }

  private func send<T: Decodable>(
    method: String,
    url: URL?,
    body: Data? = nil,
    responseType: T.Type
  ) async throws -> T {
    guard let url else {
      throw GoogleCalendarAPIError.invalidURL
    }

    let request = try authorizedRequest(method: method, url: url, body: body)

    var attempt = 0
    let maxAttempts = 3

    while true {
      let (data, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw GoogleCalendarAPIError.invalidResponse
      }

      switch httpResponse.statusCode {
      case 200...299:
        do {
          return try jsonDecoder.decode(responseType, from: data)
        } catch {
          throw GoogleCalendarAPIError.decodingFailed
        }
      case 401:
        throw GoogleCalendarAPIError.unauthorized
      case 403:
        throw GoogleCalendarAPIError.forbidden
      case 429:
        if attempt + 1 >= maxAttempts {
          throw GoogleCalendarAPIError.rateLimited
        }
      case 500...599:
        if attempt + 1 >= maxAttempts {
          let message = String(data: data, encoding: .utf8)
          throw GoogleCalendarAPIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
      default:
        let message = String(data: data, encoding: .utf8)
        throw GoogleCalendarAPIError.httpError(statusCode: httpResponse.statusCode, message: message)
      }

      attempt += 1
      let delay = UInt64(pow(2.0, Double(attempt - 1)) * 400_000_000)
      try await Task.sleep(nanoseconds: delay)
    }
  }
}

private struct EmptyGoogleResponse: Decodable {}
