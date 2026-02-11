import Foundation
import SwiftData

@Model
public class Event {
  public var id: UUID
  public var date: Date
  public var title: String
  public var notes: String?
  public var color: String
  public var createdAt: Date

  public var reminderInterval: TimeInterval?

  // Holiday support
  public var isHoliday: Bool = false
  public var holidayId: String?

  public init(
    date: Date, title: String, notes: String? = nil, color: String = "blue",
    reminderInterval: TimeInterval? = nil, isHoliday: Bool = false, holidayId: String? = nil
  ) {
    self.id = UUID()
    self.date = date
    self.title = title
    self.notes = notes
    self.color = color
    self.reminderInterval = reminderInterval
    self.createdAt = Date()
    self.isHoliday = isHoliday
    self.holidayId = holidayId
  }
}
