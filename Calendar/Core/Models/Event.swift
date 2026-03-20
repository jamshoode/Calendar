import Foundation
import SwiftData

@Model
class Event: Identifiable {
  var id: UUID
  var date: Date
  var title: String
  var notes: String?
  var color: String
  var createdAt: Date

  var reminderInterval: TimeInterval?
  var recurrenceType: String?
  var recurrenceInterval: Int?
  var recurrenceEndDate: Date?

  // Holiday support
  var isHoliday: Bool = false
  var holidayId: String?
  var isAllDay: Bool = false

  // Google Calendar sync metadata
  var externalId: String?
  var externalCalendarId: String?
  var externalUpdatedAt: Date?
  var syncOrigin: String?

  var recurrenceTypeEnum: RecurrenceType? {
    get { recurrenceType.flatMap { RecurrenceType(rawValue: $0) } }
    set { recurrenceType = newValue?.rawValue }
  }

  var isRecurring: Bool {
    recurrenceTypeEnum != nil
  }

  init(
    date: Date, title: String, notes: String? = nil, color: String = "blue",
    reminderInterval: TimeInterval? = nil,
    recurrenceType: RecurrenceType? = nil,
    recurrenceInterval: Int = 1,
    recurrenceEndDate: Date? = nil,
    isHoliday: Bool = false,
    holidayId: String? = nil,
    isAllDay: Bool = false
  ) {
    self.id = UUID()
    self.date = date
    self.title = title
    self.notes = notes
    self.color = color
    self.reminderInterval = reminderInterval
    self.recurrenceType = recurrenceType?.rawValue
    self.recurrenceInterval = recurrenceInterval
    self.recurrenceEndDate = recurrenceEndDate
    self.createdAt = Date()
    self.isHoliday = isHoliday
    self.holidayId = holidayId
    self.isAllDay = isAllDay
    self.externalId = nil
    self.externalCalendarId = nil
    self.externalUpdatedAt = nil
    self.syncOrigin = nil
  }
}
