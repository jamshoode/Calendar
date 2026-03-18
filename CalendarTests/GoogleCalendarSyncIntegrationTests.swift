import Foundation
import SwiftData
import XCTest

@testable import Calendar

@MainActor
final class GoogleCalendarSyncIntegrationTests: XCTestCase {
  private var container: ModelContainer!
  private var context: ModelContext!
  private var session: URLSession!
  private var tokenStore: IntegrationMockGoogleTokenStore!

  override func setUpWithError() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    container = try ModelContainer(
      for: Event.self,
      TodoItem.self,
      TodoCategory.self,
      GoogleCalendarConnection.self,
      GoogleCalendarSyncState.self,
      configurations: config
    )
    context = ModelContext(container)

    IntegrationURLProtocolStub.reset()
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.protocolClasses = [IntegrationURLProtocolStub.self]
    session = URLSession(configuration: sessionConfig)

    tokenStore = IntegrationMockGoogleTokenStore()
    tokenStore.tokens = GoogleOAuthTokens(
      accessToken: "access-token",
      refreshToken: "refresh-token",
      expirationDate: Date().addingTimeInterval(3600)
    )
  }

  override func tearDownWithError() throws {
    container = nil
    context = nil
    session = nil
    tokenStore = nil
    IntegrationURLProtocolStub.reset()
  }

  func testFullSyncImportsEventsAndStoresSyncToken() async throws {
    try configureConnection(selectedCalendarIds: ["cal_1"])

    IntegrationURLProtocolStub.responses = [
      .init(
        statusCode: 200,
        body: Self.jsonData(
          """
          {
            "items": [
              {
                "id": "evt_1",
                "status": "confirmed",
                "summary": "Planning",
                "description": "Q1 planning",
                "start": { "dateTime": "2026-04-10T10:00:00Z" },
                "updated": "2026-04-10T08:00:00Z"
              }
            ],
            "nextPageToken": "page_2"
          }
          """
        )
      ),
      .init(
        statusCode: 200,
        body: Self.jsonData(
          """
          {
            "items": [
              {
                "id": "evt_2",
                "status": "confirmed",
                "summary": "Retro",
                "description": "Sprint retro",
                "start": { "dateTime": "2026-04-11T09:00:00Z" },
                "updated": "2026-04-10T09:00:00Z"
              }
            ],
            "nextSyncToken": "sync_full_1"
          }
          """
        )
      ),
    ]

    let service = makeService()
    let summary = try await service.fullSyncSelectedCalendars(context: context)

    XCTAssertEqual(summary.calendarsSynced, 1)
    XCTAssertEqual(summary.imported, 2)
    XCTAssertEqual(summary.updated, 0)
    XCTAssertEqual(summary.deleted, 0)

    let events = try context.fetch(FetchDescriptor<Event>())
    XCTAssertEqual(events.count, 2)

    let states = try context.fetch(FetchDescriptor<GoogleCalendarSyncState>())
    XCTAssertEqual(states.count, 1)
    XCTAssertEqual(states.first?.calendarId, "cal_1")
    XCTAssertEqual(states.first?.nextSyncToken, "sync_full_1")
    XCTAssertNotNil(states.first?.lastFullSyncAt)
  }

  func testIncrementalSyncAppliesImportUpdateAndDelete() async throws {
    try configureConnection(selectedCalendarIds: ["cal_1"])

    let existingToUpdate = Event(date: Date(), title: "Local title", notes: nil, color: "blue")
    existingToUpdate.externalId = "evt_1"
    existingToUpdate.externalCalendarId = "cal_1"
    context.insert(existingToUpdate)

    let existingToDelete = Event(date: Date(), title: "Delete me", notes: nil, color: "red")
    existingToDelete.externalId = "evt_3"
    existingToDelete.externalCalendarId = "cal_1"
    context.insert(existingToDelete)

    let state = GoogleCalendarSyncState(calendarId: "cal_1")
    state.nextSyncToken = "sync_old"
    context.insert(state)
    try context.save()

    IntegrationURLProtocolStub.responses = [
      .init(
        statusCode: 200,
        body: Self.jsonData(
          """
          {
            "items": [
              {
                "id": "evt_1",
                "status": "confirmed",
                "summary": "Remote title",
                "description": "Updated",
                "start": { "dateTime": "2026-05-01T09:00:00Z" },
                "updated": "2026-05-01T08:30:00Z"
              },
              {
                "id": "evt_2",
                "status": "confirmed",
                "summary": "Imported",
                "description": "New",
                "start": { "dateTime": "2026-05-02T09:00:00Z" },
                "updated": "2026-05-01T08:31:00Z"
              },
              {
                "id": "evt_3",
                "status": "cancelled",
                "summary": "Delete",
                "start": { "dateTime": "2026-05-03T09:00:00Z" },
                "updated": "2026-05-01T08:32:00Z"
              }
            ],
            "nextSyncToken": "sync_new"
          }
          """
        )
      )
    ]

    let service = makeService()
    let summary = try await service.incrementalSyncSelectedCalendars(context: context)

    XCTAssertEqual(summary.calendarsSynced, 1)
    XCTAssertEqual(summary.imported, 1)
    XCTAssertEqual(summary.updated, 1)
    XCTAssertEqual(summary.deleted, 1)

    let events = try context.fetch(FetchDescriptor<Event>())
    XCTAssertEqual(events.count, 2)
    XCTAssertTrue(events.contains { $0.externalId == "evt_1" && $0.title == "Remote title" })
    XCTAssertTrue(events.contains { $0.externalId == "evt_2" && $0.title == "Imported" })
    XCTAssertFalse(events.contains { $0.externalId == "evt_3" })

    let syncedState = try XCTUnwrap(try context.fetch(FetchDescriptor<GoogleCalendarSyncState>()).first)
    XCTAssertEqual(syncedState.nextSyncToken, "sync_new")
    XCTAssertNotNil(syncedState.lastIncrementalSyncAt)
  }

  func testIncrementalSyncRecoversFrom410ByResetAndFullSync() async throws {
    try configureConnection(selectedCalendarIds: ["cal_1"])

    let staleEvent = Event(date: Date(), title: "Stale", notes: nil, color: "orange")
    staleEvent.externalId = "evt_stale"
    staleEvent.externalCalendarId = "cal_1"
    context.insert(staleEvent)

    let state = GoogleCalendarSyncState(calendarId: "cal_1")
    state.nextSyncToken = "stale_sync"
    context.insert(state)
    try context.save()

    IntegrationURLProtocolStub.responses = [
      .init(statusCode: 410, body: Self.jsonData("{\"error\":\"sync token expired\"}")),
      .init(
        statusCode: 200,
        body: Self.jsonData(
          """
          {
            "items": [
              {
                "id": "evt_fresh",
                "status": "confirmed",
                "summary": "Fresh",
                "description": "Recovered",
                "start": { "dateTime": "2026-06-01T09:00:00Z" },
                "updated": "2026-06-01T08:30:00Z"
              }
            ],
            "nextSyncToken": "fresh_sync"
          }
          """
        )
      ),
    ]

    let service = makeService()
    let summary = try await service.incrementalSyncSelectedCalendars(context: context)

    XCTAssertEqual(summary.calendarsSynced, 1)
    XCTAssertEqual(summary.imported, 1)
    XCTAssertEqual(summary.updated, 0)
    XCTAssertEqual(summary.deleted, 0)

    let events = try context.fetch(FetchDescriptor<Event>())
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events.first?.externalId, "evt_fresh")

    let syncedState = try XCTUnwrap(try context.fetch(FetchDescriptor<GoogleCalendarSyncState>()).first)
    XCTAssertEqual(syncedState.nextSyncToken, "fresh_sync")
    XCTAssertNotNil(syncedState.lastFullSyncAt)
  }

  func testGoogleWinsConflictPolicyOverridesNewerLocalMetadata() async throws {
    try configureConnection(selectedCalendarIds: ["cal_1"])

    let localEvent = Event(date: Date(), title: "Local", notes: "local notes", color: "blue")
    localEvent.externalId = "evt_conflict"
    localEvent.externalCalendarId = "cal_1"
    localEvent.externalUpdatedAt = Date().addingTimeInterval(86_400)
    context.insert(localEvent)
    try context.save()

    IntegrationURLProtocolStub.responses = [
      .init(
        statusCode: 200,
        body: Self.jsonData(
          """
          {
            "items": [
              {
                "id": "evt_conflict",
                "status": "confirmed",
                "summary": "Remote wins",
                "description": "remote notes",
                "start": { "dateTime": "2026-07-01T09:00:00Z" },
                "updated": "2026-07-01T08:00:00Z"
              }
            ],
            "nextSyncToken": "sync_conflict"
          }
          """
        )
      )
    ]

    let service = makeService()
    _ = try await service.fullSyncSelectedCalendars(context: context)

    let updated = try XCTUnwrap(
      try context.fetch(
        FetchDescriptor<Event>(
          predicate: #Predicate { $0.externalId == "evt_conflict" && $0.externalCalendarId == "cal_1" }
        )
      ).first
    )

    XCTAssertEqual(updated.title, "Remote wins")
    XCTAssertEqual(updated.notes, "remote notes")
    XCTAssertEqual(updated.syncOrigin, "google")
  }

  func testTodoRoundTripCreatesAllDayRemoteThenDeletesWhenDueDateCleared() async throws {
    try configureConnection(selectedCalendarIds: ["cal_1"])

    let localNoon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    let todo = TodoItem(title: "Pay bill", dueDate: localNoon)
    context.insert(todo)
    try context.save()

    IntegrationURLProtocolStub.responses = [
      .init(
        statusCode: 200,
        body: Self.jsonData(
          """
          {
            "id": "todo_evt_1",
            "status": "confirmed",
            "summary": "Pay bill",
            "start": { "date": "2026-01-01" },
            "end": { "date": "2026-01-02" },
            "updated": "2026-08-01T08:00:00Z"
          }
          """
        )
      ),
      .init(statusCode: 200, body: Self.jsonData("{}")),
    ]

    let service = makeService()
    try await service.pushLocalTodoAsAllDayEvent(todo, context: context)

    XCTAssertEqual(todo.externalId, "todo_evt_1")
    XCTAssertEqual(todo.externalCalendarId, "cal_1")
    XCTAssertEqual(todo.syncOrigin, "local")

    let postRequest = try XCTUnwrap(IntegrationURLProtocolStub.requests.first)
    XCTAssertEqual(postRequest.httpMethod, "POST")
    let postBody = try XCTUnwrap(postRequest.httpBody)
    let payload = try JSONDecoder().decode(AllDayPayload.self, from: postBody)
    XCTAssertNotNil(payload.start.date)
    XCTAssertNotNil(payload.end.date)

    let calendar = Calendar(identifier: .gregorian)
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"

    let start = try XCTUnwrap(formatter.date(from: try XCTUnwrap(payload.start.date)))
    let end = try XCTUnwrap(formatter.date(from: try XCTUnwrap(payload.end.date)))
    XCTAssertEqual(calendar.dateComponents([.day], from: start, to: end).day, 1)

    todo.dueDate = nil
    try context.save()

    try await service.pushLocalTodoAsAllDayEvent(todo, context: context)

    XCTAssertNil(todo.externalId)
    XCTAssertNil(todo.externalCalendarId)
    XCTAssertNil(todo.externalUpdatedAt)

    let deleteRequest = try XCTUnwrap(IntegrationURLProtocolStub.requests.last)
    XCTAssertEqual(deleteRequest.httpMethod, "DELETE")
    XCTAssertTrue(deleteRequest.url?.absoluteString.contains("/events/todo_evt_1") == true)
  }

  private func makeService() -> GoogleCalendarSyncService {
    GoogleCalendarSyncService(
      apiClient: GoogleCalendarAPIClient(session: session, tokenStore: tokenStore)
    )
  }

  private func configureConnection(selectedCalendarIds: [String]) throws {
    let connection = GoogleCalendarConnection()
    connection.hasConsent = true
    connection.isConnected = true
    connection.selectedCalendarIds = selectedCalendarIds
    context.insert(connection)
    try context.save()
  }

  private static func jsonData(_ value: String) -> Data {
    Data(value.utf8)
  }
}

private struct AllDayPayload: Decodable {
  let summary: String
  let start: DateOnlyPayload
  let end: DateOnlyPayload

  struct DateOnlyPayload: Decodable {
    let date: String?
  }
}

private final class IntegrationMockGoogleTokenStore: GoogleTokenStore {
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

private final class IntegrationURLProtocolStub: URLProtocol {
  struct StubResponse {
    let statusCode: Int
    let body: Data
  }

  static var responses: [StubResponse] = []
  static var requests: [URLRequest] = []

  static func reset() {
    responses = []
    requests = []
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    Self.requests.append(request)

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
