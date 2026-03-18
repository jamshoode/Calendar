import Foundation
import SwiftData

@MainActor
final class GoogleCalendarDiscoveryService {
  static let shared = GoogleCalendarDiscoveryService()

  private let apiClient: GoogleCalendarAPIClient

  init(apiClient: GoogleCalendarAPIClient = GoogleCalendarAPIClient()) {
    self.apiClient = apiClient
  }

  struct DiscoveryResult {
    let calendars: [GoogleCalendarListEntryDTO]
    let selectedCalendarIds: [String]
  }

  func refreshCalendars(context: ModelContext) async throws -> DiscoveryResult {
    var pageToken: String?
    var allCalendars: [GoogleCalendarListEntryDTO] = []

    repeat {
      let response = try await apiClient.listCalendars(pageToken: pageToken)
      allCalendars.append(contentsOf: response.items)
      pageToken = response.nextPageToken
    } while pageToken != nil

    let connection = try upsertConnection(context: context)

    if connection.selectedCalendarIds.isEmpty {
      let defaults = allCalendars.filter { $0.selected == true || $0.primary == true }.map(\.id)
      connection.selectedCalendarIds = defaults.isEmpty ? allCalendars.prefix(1).map(\.id) : defaults
    } else {
      let validIds = Set(allCalendars.map(\.id))
      connection.selectedCalendarIds = connection.selectedCalendarIds.filter { validIds.contains($0) }
    }

    connection.updatedAt = Date()
    try context.save()

    return DiscoveryResult(
      calendars: allCalendars,
      selectedCalendarIds: connection.selectedCalendarIds
    )
  }

  func updateSelectedCalendars(_ ids: [String], context: ModelContext) throws {
    let connection = try upsertConnection(context: context)
    connection.selectedCalendarIds = Array(Set(ids)).sorted()
    connection.updatedAt = Date()
    try context.save()
  }

  private func upsertConnection(context: ModelContext) throws -> GoogleCalendarConnection {
    let descriptor = FetchDescriptor<GoogleCalendarConnection>(
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )

    if let existing = try context.fetch(descriptor).first {
      return existing
    }

    let connection = GoogleCalendarConnection()
    context.insert(connection)
    return connection
  }
}
