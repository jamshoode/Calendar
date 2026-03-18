import Foundation
import SwiftData

@Model
final class GoogleCalendarSyncState {
  var id: UUID
  var calendarId: String
  var nextSyncToken: String?
  var nextPageToken: String?
  var lastFullSyncAt: Date?
  var lastIncrementalSyncAt: Date?
  var updatedAt: Date

  init(calendarId: String) {
    self.id = UUID()
    self.calendarId = calendarId
    self.nextSyncToken = nil
    self.nextPageToken = nil
    self.lastFullSyncAt = nil
    self.lastIncrementalSyncAt = nil
    self.updatedAt = Date()
  }
}
