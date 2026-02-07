import SwiftData
import SwiftUI
import WidgetKit

class EventViewModel {
  func addEvent(
    date: Date, title: String, notes: String?, color: String, reminderInterval: TimeInterval?,
    context: ModelContext
  ) {
    let event = Event(
      date: date, title: title, notes: notes, color: color, reminderInterval: reminderInterval)
    context.insert(event)
    try? context.save()
    rescheduleAllNotifications(context: context)
    syncEventsToWidget(context: context)
  }

  func updateEvent(
    _ event: Event, title: String, notes: String?, color: String, reminderInterval: TimeInterval?,
    context: ModelContext
  ) {
    event.title = title
    event.notes = notes
    event.color = color
    event.reminderInterval = reminderInterval
    try? context.save()
    rescheduleAllNotifications(context: context)
    syncEventsToWidget(context: context)
  }

  func deleteEvent(_ event: Event, context: ModelContext) {
    context.delete(event)
    try? context.save()
    rescheduleAllNotifications(context: context)
    syncEventsToWidget(context: context)
  }

  func rescheduleAllNotifications(context: ModelContext) {
    let now = Date()
    let descriptor = FetchDescriptor<Event>(
      predicate: #Predicate { $0.date > now },
      sortBy: [SortDescriptor(\.date)]
    )

    do {
      let events = try context.fetch(descriptor)
      NotificationService.shared.syncEventNotifications(events: events)
    } catch {}
  }

  func syncEventsToWidget(context: ModelContext) {
    let calendar = Calendar.current
    let today = Date()

    guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return }
    let rangeStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
    let rangeEnd = calendar.date(byAdding: .day, value: 15, to: weekStart)!

    let descriptor = FetchDescriptor<Event>(
      predicate: #Predicate { event in
        event.date >= rangeStart && event.date <= rangeEnd
      },
      sortBy: [SortDescriptor(\.date)]
    )

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    var eventMap: [String: [String]] = [:]

    do {
      let events = try context.fetch(descriptor)
      for event in events {
        let key = formatter.string(from: event.date)
        var colors = eventMap[key] ?? []
        if colors.count < 3 {
          colors.append(event.color)
        }
        eventMap[key] = colors
      }
    } catch {}

    if let data = try? JSONSerialization.data(withJSONObject: eventMap),
      let jsonString = String(data: data, encoding: .utf8)
    {
      let defaults = UserDefaults(suiteName: "group.com.shoode.calendar")
      defaults?.set(jsonString, forKey: "widgetEventData")
      defaults?.synchronize()
    }

    WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
  }
}
