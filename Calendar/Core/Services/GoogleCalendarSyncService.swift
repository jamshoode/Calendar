import Foundation
import SwiftData

@MainActor
final class GoogleCalendarSyncService {
  static let shared = GoogleCalendarSyncService()

  private let apiClient: GoogleCalendarAPIClient

  init(apiClient: GoogleCalendarAPIClient = GoogleCalendarAPIClient()) {
    self.apiClient = apiClient
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
        context.delete(existing)
        return .deleted
      }
      return .ignored
    }

    guard let title = dto.summary, let date = Self.parseEventStart(dto.start) else {
      return .ignored
    }

    let updatedAt = Self.parseUpdatedAt(dto.updated)

    if let existing {
      existing.title = title
      existing.notes = dto.description
      existing.date = date
      existing.externalUpdatedAt = updatedAt
      existing.syncOrigin = "google"
      return .updated
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

  func pushLocalEvent(_ event: Event, context: ModelContext) async throws {
    if event.syncOrigin == "google" {
      event.syncOrigin = nil
      try context.save()
      return
    }

    guard let calendarId = event.externalCalendarId ?? try defaultCalendarId(context: context) else {
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

    try await apiClient.deleteEvent(calendarId: externalCalendarId, eventId: externalId)
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
