import Foundation

enum GoogleCalendarAPIError: LocalizedError {
  case missingTokens
  case expiredTokens
  case missingClientId
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
    case .missingClientId:
      return "Google OAuth client ID is missing."
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
    var components = URLComponents(
      string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")
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

  func createEvent(calendarId: String, request: GoogleEventUpsertRequest) async throws
    -> GoogleEventDTO
  {
    let escapedCalendarId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    guard let escapedCalendarId else {
      throw GoogleCalendarAPIError.invalidURL
    }

    let url = URL(
      string: "https://www.googleapis.com/calendar/v3/calendars/\(escapedCalendarId)/events")
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
      string:
        "https://www.googleapis.com/calendar/v3/calendars/\(escapedCalendarId)/events/\(escapedEventId)"
    )
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
      string:
        "https://www.googleapis.com/calendar/v3/calendars/\(escapedCalendarId)/events/\(escapedEventId)"
    )

    _ = try await send(method: "DELETE", url: url, responseType: EmptyGoogleResponse.self)
  }

  private func authorizedRequest(method: String, url: URL, body: Data? = nil) throws -> URLRequest {
    guard let tokens = try tokenStore.loadTokens() else {
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

    var request = try await authorizedRequestWithRefresh(method: method, url: url, body: body)
    var refreshedAfterUnauthorized = false

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
        if !refreshedAfterUnauthorized {
          do {
            let refreshedTokens = try await forceRefreshTokens()
            request.setValue(
              "Bearer \(refreshedTokens.accessToken)", forHTTPHeaderField: "Authorization")
            refreshedAfterUnauthorized = true
            continue
          } catch {
            throw GoogleCalendarAPIError.unauthorized
          }
        }
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
          throw GoogleCalendarAPIError.httpError(
            statusCode: httpResponse.statusCode, message: message)
        }
      default:
        let message = String(data: data, encoding: .utf8)
        throw GoogleCalendarAPIError.httpError(
          statusCode: httpResponse.statusCode, message: message)
      }

      attempt += 1
      let delay = UInt64(pow(2.0, Double(attempt - 1)) * 400_000_000)
      try await Task.sleep(nanoseconds: delay)
    }
  }

  private func authorizedRequestWithRefresh(method: String, url: URL, body: Data? = nil) async throws
    -> URLRequest
  {
    guard let tokens = try tokenStore.loadTokens() else {
      throw GoogleCalendarAPIError.missingTokens
    }

    let validTokens: GoogleOAuthTokens
    if tokens.expirationDate <= Date().addingTimeInterval(60) {
      validTokens = try await refreshTokens(using: tokens)
      try tokenStore.saveTokens(validTokens)
    } else {
      validTokens = tokens
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(validTokens.accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if let body {
      request.httpBody = body
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    return request
  }

  private func forceRefreshTokens() async throws -> GoogleOAuthTokens {
    guard let tokens = try tokenStore.loadTokens() else {
      throw GoogleCalendarAPIError.missingTokens
    }

    let refreshed = try await refreshTokens(using: tokens)
    try tokenStore.saveTokens(refreshed)
    return refreshed
  }

  private func refreshTokens(using tokens: GoogleOAuthTokens) async throws -> GoogleOAuthTokens {
    guard let clientId = resolveClientID(), !clientId.isEmpty else {
      throw GoogleCalendarAPIError.missingClientId
    }

    guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
      throw GoogleCalendarAPIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = formURLEncodedBody([
      "client_id": clientId,
      "grant_type": "refresh_token",
      "refresh_token": tokens.refreshToken,
    ])

    let (data, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw GoogleCalendarAPIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      if let payload = try? jsonDecoder.decode(GoogleOAuthRefreshFailureResponse.self, from: data),
        payload.error == "invalid_grant"
      {
        throw GoogleCalendarAPIError.unauthorized
      }
      let message = String(data: data, encoding: .utf8)
      throw GoogleCalendarAPIError.httpError(statusCode: httpResponse.statusCode, message: message)
    }

    let payload: GoogleOAuthRefreshResponse
    do {
      payload = try jsonDecoder.decode(GoogleOAuthRefreshResponse.self, from: data)
    } catch {
      throw GoogleCalendarAPIError.decodingFailed
    }

    let nextRefreshToken = payload.refreshToken?.isEmpty == false
      ? payload.refreshToken!
      : tokens.refreshToken
    let expirationDate = Date().addingTimeInterval(TimeInterval(max(payload.expiresIn, 60)))

    return GoogleOAuthTokens(
      accessToken: payload.accessToken,
      refreshToken: nextRefreshToken,
      expirationDate: expirationDate
    )
  }

  private func resolveClientID() -> String? {
    if let configured = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
      let trimmed = configured.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
    }

    guard
      let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
      let data = try? Data(contentsOf: url),
      let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: Any],
      let clientID = plist["CLIENT_ID"] as? String
    else {
      return nil
    }

    let trimmed = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func formURLEncodedBody(_ values: [String: String]) -> Data? {
    let encoded = values
      .map { key, value in
        "\(percentEncode(key))=\(percentEncode(value))"
      }
      .sorted()
      .joined(separator: "&")
    return encoded.data(using: .utf8)
  }

  private func percentEncode(_ value: String) -> String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "+&=")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }
}

private struct EmptyGoogleResponse: Decodable {}

private struct GoogleOAuthRefreshResponse: Decodable {
  let accessToken: String
  let expiresIn: Int
  let refreshToken: String?

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case expiresIn = "expires_in"
    case refreshToken = "refresh_token"
  }
}

private struct GoogleOAuthRefreshFailureResponse: Decodable {
  let error: String
}
