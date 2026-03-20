import Foundation
import XCTest

@testable import Calendar

final class GoogleCalendarCoreTests: XCTestCase {
  private var session: URLSession!
  private var tokenStore: MockGoogleTokenStore!

  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()

    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    session = URLSession(configuration: config)

    tokenStore = MockGoogleTokenStore()
    tokenStore.tokens = GoogleOAuthTokens(
      accessToken: "access-token",
      refreshToken: "refresh-token",
      expirationDate: Date().addingTimeInterval(3600)
    )
  }

  override func tearDown() {
    session = nil
    tokenStore = nil
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testDTODecodingEventList() throws {
    let json = """
      {
        "items": [
          {
            "id": "evt_1",
            "status": "confirmed",
            "summary": "Team Sync",
            "description": "Weekly update",
            "start": { "dateTime": "2026-03-20T10:00:00Z" },
            "end": { "dateTime": "2026-03-20T11:00:00Z" },
            "updated": "2026-03-19T08:00:00Z"
          }
        ],
        "nextSyncToken": "sync_123"
      }
      """

    let data = try XCTUnwrap(json.data(using: .utf8))
    let decoded = try JSONDecoder().decode(GoogleEventListResponse.self, from: data)

    XCTAssertEqual(decoded.items.count, 1)
    XCTAssertEqual(decoded.items.first?.id, "evt_1")
    XCTAssertEqual(decoded.nextSyncToken, "sync_123")
  }

  func testAPIClientMapsUnauthorized() async {
    URLProtocolStub.responses = [
      .init(statusCode: 401, body: Data("{}".utf8))
    ]

    let client = GoogleCalendarAPIClient(session: session, tokenStore: tokenStore)

    do {
      _ = try await client.listCalendars()
      XCTFail("Expected unauthorized error")
    } catch let error as GoogleCalendarAPIError {
      guard case .unauthorized = error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  func testAPIClientRetriesRateLimitThenSucceeds() async throws {
    let successBody =
      Data(
        "{".utf8
      )
      + Data("\"items\":[{\"id\":\"cal_1\",\"summary\":\"Primary\"}],\"nextPageToken\":null}".utf8)

    URLProtocolStub.responses = [
      .init(statusCode: 429, body: Data("{}".utf8)),
      .init(statusCode: 200, body: successBody),
    ]

    let client = GoogleCalendarAPIClient(session: session, tokenStore: tokenStore)
    let response = try await client.listCalendars()

    XCTAssertEqual(URLProtocolStub.requestCount, 2)
    XCTAssertEqual(response.items.count, 1)
    XCTAssertEqual(response.items.first?.id, "cal_1")
  }

  @MainActor
  func testDeleteRemoteEventDoesNotThrowWhenTokensMissing() async throws {
    let emptyTokenStore = MockGoogleTokenStore()
    emptyTokenStore.tokens = nil

    let client = GoogleCalendarAPIClient(session: session, tokenStore: emptyTokenStore)
    let service = GoogleCalendarSyncService(apiClient: client)

    do {
      try await service.deleteRemoteEvent(
        externalId: "evt_1",
        externalCalendarId: "cal_1"
      )
    } catch {
      XCTFail("Expected local-delete-safe behavior, got error: \(error)")
    }
  }
}

private final class MockGoogleTokenStore: GoogleTokenStore {
  var tokens: GoogleOAuthTokens?

  func saveTokens(_ tokens: GoogleOAuthTokens) throws {
    self.tokens = tokens
  }

  func loadTokens() throws -> GoogleOAuthTokens? {
    tokens
  }

  func deleteTokens() throws {
    tokens = nil
  }
}

private final class URLProtocolStub: URLProtocol {
  struct StubResponse {
    let statusCode: Int
    let body: Data
  }

  static var responses: [StubResponse] = []
  static var requestCount = 0

  static func reset() {
    responses = []
    requestCount = 0
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    Self.requestCount += 1

    guard !Self.responses.isEmpty else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    let stub = Self.responses.removeFirst()
    let response = HTTPURLResponse(
      url: request.url ?? URL(string: "https://example.com")!,
      statusCode: stub.statusCode,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    )!

    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: stub.body)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
