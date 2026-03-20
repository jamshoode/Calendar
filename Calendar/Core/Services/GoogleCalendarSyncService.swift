import Foundation
import SwiftData

@MainActor
final class GoogleCalendarSyncService {
  static let shared = GoogleCalendarSyncService()

  private let apiClient: GoogleCalendarAPIClient
  private let conflictPolicy: GoogleConflictPolicy

  enum GoogleConflictPolicy {
    case googleWins
  }

  init(
    apiClient: GoogleCalendarAPIClient? = nil,
    conflictPolicy: GoogleConflictPolicy = .googleWins
  ) {
    self.apiClient = apiClient ?? GoogleCalendarAPIClient()
    self.conflictPolicy = conflictPolicy
  }

  struct FullSyncSummary {
    let calendarsSynced: Int
    let imported: Int
    let updated: Int
    let deleted: Int
  }

  struct IncrementalSyncSummary {
    let calendarsSynced: Int
    let imported: Int
    let updated: Int
    let deleted: Int
  }

  func syncIfNeededOnStartup(context: ModelContext) async {
    do {
      let connection = try upsertConnection(context: context)
      guard connection.hasConsent, connection.isConnected else { return }
      if let lastSyncAt = connection.lastSyncAt,
        Date().timeIntervalSince(lastSyncAt) < Constants.GoogleCalendar.syncThrottleSeconds
      {
        return
      }

      _ = try await incrementalSyncSelectedCalendars(context: context)
    } catch {
      let connection = (try? upsertConnection(context: context))
      if isAuthorizationFailure(error) {
        connection?.isConnected = false
        connection?.lastSyncStatus = "unauthorized"
      } else {
        connection?.lastSyncStatus = "error"
      }
      connection?.lastSyncErrorMessage = error.localizedDescription
      connection?.lastSyncErrorAt = Date()
      connection?.updatedAt = Date()
      try? context.save()
    }
  }

  func fullSyncSelectedCalendars(context: ModelContext) async throws -> FullSyncSummary {
    let connection = try upsertConnection(context: context)
    let selectedCalendarIds = connection.selectedCalendarIds

    var calendarsSynced = 0
    var imported = 0
    var updated = 0
    var deleted = 0

    for calendarId in selectedCalendarIds {
      let calendarSummary = try await fullSyncCalendar(calendarId: calendarId, context: context)
      calendarsSynced += 1
      imported += calendarSummary.imported
      updated += calendarSummary.updated
      deleted += calendarSummary.deleted
    }

    connection.lastSyncAt = Date()
    connection.lastSyncStatus = "ok"
    connection.lastSyncErrorMessage = nil
    connection.lastSyncErrorAt = nil
    connection.updatedAt = Date()
    try context.save()

    return FullSyncSummary(
      calendarsSynced: calendarsSynced,
      imported: imported,
      updated: updated,
      deleted: deleted
    )
  }

  func incrementalSyncSelectedCalendars(context: ModelContext) async throws
    -> IncrementalSyncSummary
  {
    let connection = try upsertConnection(context: context)
    let selectedCalendarIds = connection.selectedCalendarIds

    var calendarsSynced = 0
    var imported = 0
    var updated = 0
    var deleted = 0

    for calendarId in selectedCalendarIds {
      let calendarSummary = try await incrementalSyncCalendar(
        calendarId: calendarId, context: context)
      calendarsSynced += 1
      imported += calendarSummary.imported
      updated += calendarSummary.updated
      deleted += calendarSummary.deleted
    }

    connection.lastSyncAt = Date()
    connection.lastSyncStatus = "ok"
    connection.lastSyncErrorMessage = nil
    connection.lastSyncErrorAt = nil
    connection.updatedAt = Date()
    try context.save()

    return IncrementalSyncSummary(
      calendarsSynced: calendarsSynced,
      imported: imported,
      updated: updated,
      deleted: deleted
    )
  }

  struct CalendarFullSyncSummary {
    let imported: Int
    let updated: Int
    let deleted: Int
  }

  struct CalendarIncrementalSyncSummary {
    let imported: Int
    let updated: Int
    let deleted: Int
  }

  private func fullSyncCalendar(calendarId: String, context: ModelContext) async throws
    -> CalendarFullSyncSummary
  {
    var pageToken: String?
    var imported = 0
    var updated = 0
    var deleted = 0
    var lastSyncToken: String?

    repeat {
      let response = try await apiClient.listEvents(
        calendarId: calendarId,
        syncToken: nil,
        pageToken: pageToken
      )

      for dto in response.items {
        let outcome = try applyRemoteEvent(dto, calendarId: calendarId, context: context)
        switch outcome {
        case .imported:
          imported += 1
        case .updated:
          updated += 1
        case .deleted:
          deleted += 1
        case .ignored:
          break
        }
      }

      pageToken = response.nextPageToken
      lastSyncToken = response.nextSyncToken ?? lastSyncToken
    } while pageToken != nil

    if let lastSyncToken {
      let state = try upsertSyncState(calendarId: calendarId, context: context)
      state.nextSyncToken = lastSyncToken
      state.nextPageToken = nil
      state.lastFullSyncAt = Date()
      state.updatedAt = Date()
    }

    try context.save()

    return CalendarFullSyncSummary(imported: imported, updated: updated, deleted: deleted)
  }

  private func incrementalSyncCalendar(calendarId: String, context: ModelContext) async throws
    -> CalendarIncrementalSyncSummary
  {
    let state = try upsertSyncState(calendarId: calendarId, context: context)

    guard let syncToken = state.nextSyncToken, !syncToken.isEmpty else {
      let full = try await fullSyncCalendar(calendarId: calendarId, context: context)
      return CalendarIncrementalSyncSummary(
        imported: full.imported,
        updated: full.updated,
        deleted: full.deleted
      )
    }

    var pageToken: String?
    var imported = 0
    var updated = 0
    var deleted = 0
    var nextSyncToken: String?

    do {
      repeat {
        let response = try await apiClient.listEvents(
          calendarId: calendarId,
          syncToken: syncToken,
          pageToken: pageToken
        )

        for dto in response.items {
          let outcome = try applyRemoteEvent(dto, calendarId: calendarId, context: context)
          switch outcome {
          case .imported:
            imported += 1
          case .updated:
            updated += 1
          case .deleted:
            deleted += 1
          case .ignored:
            break
          }
        }

        pageToken = response.nextPageToken
        nextSyncToken = response.nextSyncToken ?? nextSyncToken
      } while pageToken != nil
    } catch GoogleCalendarAPIError.httpError(let statusCode, _) where statusCode == 410 {
      // Sync token invalidation requires local shadow reset and a new full sync.
      try resetCalendarSyncState(calendarId: calendarId, context: context)
      let full = try await fullSyncCalendar(calendarId: calendarId, context: context)
      return CalendarIncrementalSyncSummary(
        imported: full.imported,
        updated: full.updated,
        deleted: full.deleted
      )
    }

    state.nextSyncToken = nextSyncToken ?? state.nextSyncToken
    state.nextPageToken = nil
    state.lastIncrementalSyncAt = Date()
    state.updatedAt = Date()
    try context.save()

    return CalendarIncrementalSyncSummary(imported: imported, updated: updated, deleted: deleted)
  }

  private enum ApplyOutcome {
    case imported
    case updated
    case deleted
    case ignored
  }

  private func applyRemoteEvent(_ dto: GoogleEventDTO, calendarId: String, context: ModelContext)
    throws
    -> ApplyOutcome
  {
    let eventId = dto.id

    let descriptor = FetchDescriptor<Event>(
      predicate: #Predicate { event in
        event.externalId == eventId && event.externalCalendarId == calendarId
      }
    )
    let existing = try context.fetch(descriptor).first

    if dto.isDeleted {
      if let existing {
        if shouldApplyRemoteChange(localUpdatedAt: existing.externalUpdatedAt, remoteUpdatedAt: nil)
        {
          context.delete(existing)
          return .deleted
        }
        return .ignored
      }
      return .ignored
    }

    guard let title = dto.summary, let date = Self.parseEventStart(dto.start) else {
      return .ignored
    }

    let updatedAt = Self.parseUpdatedAt(dto.updated)

    if let existing {
      if shouldApplyRemoteChange(
        localUpdatedAt: existing.externalUpdatedAt, remoteUpdatedAt: updatedAt)
      {
        existing.title = title
        existing.notes = dto.description
        existing.date = date
        existing.externalUpdatedAt = updatedAt
        existing.syncOrigin = "google"
        return .updated
      }
      return .ignored
    }

    let event = Event(
      date: date,
      title: title,
      notes: dto.description,
      color: "blue"
    )
    event.externalId = eventId
    event.externalCalendarId = calendarId
    event.externalUpdatedAt = updatedAt
    event.syncOrigin = "google"
    context.insert(event)
    return .imported
  }

  private func shouldApplyRemoteChange(localUpdatedAt: Date?, remoteUpdatedAt: Date?) -> Bool {
    switch conflictPolicy {
    case .googleWins:
      return true
    }
  }

  private func isAuthorizationFailure(_ error: Error) -> Bool {
    switch error {
    case GoogleCalendarAPIError.missingTokens,
      GoogleCalendarAPIError.expiredTokens,
      GoogleCalendarAPIError.unauthorized:
      return true
    default:
      return false
    }
  }

  func pushLocalEvent(_ event: Event, context: ModelContext) async throws {
    if event.syncOrigin == "google" {
      event.syncOrigin = nil
      try context.save()
      return
    }

    let calendarId: String
    if let externalCalendarId = event.externalCalendarId {
      calendarId = externalCalendarId
    } else if let fallbackCalendarId = try defaultCalendarId(context: context) {
      calendarId = fallbackCalendarId
    } else {
      return
    }

    let request = makeUpsertRequest(from: event)
    let remote: GoogleEventDTO

    if let externalId = event.externalId, !externalId.isEmpty {
      remote = try await apiClient.patchEvent(
        calendarId: calendarId,
        eventId: externalId,
        request: request
      )
    } else {
      remote = try await apiClient.createEvent(
        calendarId: calendarId,
        request: request
      )
    }

    event.externalId = remote.id
    event.externalCalendarId = calendarId
    event.externalUpdatedAt = Self.parseUpdatedAt(remote.updated)
    event.syncOrigin = "local"
    try context.save()
  }

  func deleteRemoteEvent(
    externalId: String?,
    externalCalendarId: String?
  ) async throws {
    guard
      let externalId,
      !externalId.isEmpty,
      let externalCalendarId,
      !externalCalendarId.isEmpty
    else {
      return
    }

    do {
      try await apiClient.deleteEvent(calendarId: externalCalendarId, eventId: externalId)
    } catch GoogleCalendarAPIError.missingTokens,
      GoogleCalendarAPIError.expiredTokens,
      GoogleCalendarAPIError.unauthorized
    {
      // Allow local deletion to proceed when OAuth state is no longer available.
      return
    }
  }

  func pushLocalTodoAsAllDayEvent(_ todo: TodoItem, context: ModelContext) async throws {
    if todo.syncOrigin == "google" {
      todo.syncOrigin = nil
      try context.save()
      return
    }

    guard let dueDate = todo.dueDate else {
      try await deleteRemoteEvent(
        externalId: todo.externalId, externalCalendarId: todo.externalCalendarId)
      clearTodoExternalMapping(todo)
      try context.save()
      return
    }

    let calendarId: String
    if let externalCalendarId = todo.externalCalendarId {
      calendarId = externalCalendarId
    } else if let fallbackCalendarId = try defaultCalendarId(context: context) {
      calendarId = fallbackCalendarId
    } else {
      return
    }

    let request = makeAllDayTodoRequest(from: todo, dueDate: dueDate)
    let remote: GoogleEventDTO

    if let externalId = todo.externalId, !externalId.isEmpty {
      remote = try await apiClient.patchEvent(
        calendarId: calendarId,
        eventId: externalId,
        request: request
      )
    } else {
      remote = try await apiClient.createEvent(
        calendarId: calendarId,
        request: request
      )
    }

    todo.externalId = remote.id
    todo.externalCalendarId = calendarId
    todo.externalUpdatedAt = Self.parseUpdatedAt(remote.updated)
    todo.syncOrigin = "local"
    try context.save()
  }

  func deleteRemoteTodoEvent(externalId: String?, externalCalendarId: String?) async throws {
    try await deleteRemoteEvent(externalId: externalId, externalCalendarId: externalCalendarId)
  }

  func clearLocalImportedGoogleData(context: ModelContext) throws {
    let importedEvents = try context.fetch(
      FetchDescriptor<Event>(
        predicate: #Predicate { event in
          event.syncOrigin == "google"
        }
      )
    )

    for event in importedEvents {
      context.delete(event)
    }

    // Some previously imported holiday rows may be edited later and lose "google"
    // syncOrigin while still carrying Google linkage. Purge those on disconnect too.
    let googleLinkedHolidayEvents = try context.fetch(
      FetchDescriptor<Event>(
        predicate: #Predicate { event in
          event.isHoliday == true && event.externalCalendarId != nil
        }
      )
    )

    for holidayEvent in googleLinkedHolidayEvents {
      context.delete(holidayEvent)
    }

    let allEvents = try context.fetch(FetchDescriptor<Event>())
    for event in allEvents {
      guard let externalCalendarId = event.externalCalendarId else { continue }
      if Self.isGoogleHolidayCalendarId(externalCalendarId) {
        context.delete(event)
      }
    }

    let importedTodos = try context.fetch(
      FetchDescriptor<TodoItem>(
        predicate: #Predicate { todo in
          todo.syncOrigin == "google"
        }
      )
    )

    for todo in importedTodos {
      context.delete(todo)
    }

    let syncStates = try context.fetch(FetchDescriptor<GoogleCalendarSyncState>())
    for state in syncStates {
      context.delete(state)
    }

    try context.save()
  }

  static func isGoogleHolidayCalendarId(_ calendarId: String) -> Bool {
    let normalized = calendarId.lowercased()
    return normalized.contains("#holiday@")
      || normalized.contains("holiday.calendar.google.com")
  }

  private func upsertConnection(context: ModelContext) throws -> GoogleCalendarConnection {
    let descriptor = FetchDescriptor<GoogleCalendarConnection>(
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )

    if let connection = try context.fetch(descriptor).first {
      return connection
    }

    let connection = GoogleCalendarConnection()
    context.insert(connection)
    return connection
  }

  private func defaultCalendarId(context: ModelContext) throws -> String? {
    let connection = try upsertConnection(context: context)
    return connection.selectedCalendarIds.first
  }

  private func makeUpsertRequest(from event: Event) -> GoogleEventUpsertRequest {
    let startDate = event.date
    let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    let timeZone = TimeZone.current.identifier

    return GoogleEventUpsertRequest(
      summary: event.title,
      description: event.notes,
      start: .init(
        date: nil,
        dateTime: formatter.string(from: startDate),
        timeZone: timeZone
      ),
      end: .init(
        date: nil,
        dateTime: formatter.string(from: endDate),
        timeZone: timeZone
      )
    )
  }

  private func makeAllDayTodoRequest(from todo: TodoItem, dueDate: Date) -> GoogleEventUpsertRequest
  {
    let calendar = Calendar(identifier: .gregorian)
    let startOfDay = calendar.startOfDay(for: dueDate)
    let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"

    return GoogleEventUpsertRequest(
      summary: todo.title,
      description: todo.notes,
      start: .init(
        date: formatter.string(from: startOfDay),
        dateTime: nil,
        timeZone: nil
      ),
      end: .init(
        date: formatter.string(from: nextDay),
        dateTime: nil,
        timeZone: nil
      )
    )
  }

  private func clearTodoExternalMapping(_ todo: TodoItem) {
    todo.externalId = nil
    todo.externalCalendarId = nil
    todo.externalUpdatedAt = nil
  }

  private func upsertSyncState(calendarId: String, context: ModelContext) throws
    -> GoogleCalendarSyncState
  {
    let descriptor = FetchDescriptor<GoogleCalendarSyncState>(
      predicate: #Predicate { state in
        state.calendarId == calendarId
      }
    )

    if let state = try context.fetch(descriptor).first {
      return state
    }

    let state = GoogleCalendarSyncState(calendarId: calendarId)
    context.insert(state)
    return state
  }

  private func resetCalendarSyncState(calendarId: String, context: ModelContext) throws {
    let events = try context.fetch(
      FetchDescriptor<Event>(
        predicate: #Predicate { event in
          event.externalCalendarId == calendarId
        }
      ))

    for event in events {
      context.delete(event)
    }

    let state = try upsertSyncState(calendarId: calendarId, context: context)
    state.nextSyncToken = nil
    state.nextPageToken = nil
    state.lastIncrementalSyncAt = nil
    state.updatedAt = Date()
    try context.save()
  }

  private static func parseEventStart(_ start: GoogleEventDateTimeDTO?) -> Date? {
    guard let start else { return nil }

    if let dateTime = start.dateTime {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = formatter.date(from: dateTime) {
        return date
      }

      let fallback = ISO8601DateFormatter()
      fallback.formatOptions = [.withInternetDateTime]
      return fallback.date(from: dateTime)
    }

    if let date = start.date {
      let formatter = DateFormatter()
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
      formatter.dateFormat = "yyyy-MM-dd"
      return formatter.date(from: date)
    }

    return nil
  }

  private static func parseUpdatedAt(_ value: String?) -> Date? {
    guard let value else { return nil }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) {
      return date
    }

    let fallback = ISO8601DateFormatter()
    fallback.formatOptions = [.withInternetDateTime]
    return fallback.date(from: value)
  }
}
