import Foundation
import SwiftData

@Model
final class GoogleCalendarConnection {
  var id: UUID
  var hasConsent: Bool
  var isConnected: Bool
  var accountEmail: String?
  var accountDisplayName: String?
  var selectedCalendarIds: [String]
  var lastSyncAt: Date?
  var lastSyncStatus: String?
  var lastSyncErrorMessage: String?
  var lastSyncErrorAt: Date?
  var createdAt: Date
  var updatedAt: Date

  init() {
    self.id = UUID()
    self.hasConsent = false
    self.isConnected = false
    self.accountEmail = nil
    self.accountDisplayName = nil
    self.selectedCalendarIds = []
    self.lastSyncAt = nil
    self.lastSyncStatus = nil
    self.lastSyncErrorMessage = nil
    self.lastSyncErrorAt = nil
    self.createdAt = Date()
    self.updatedAt = Date()
  }
}
