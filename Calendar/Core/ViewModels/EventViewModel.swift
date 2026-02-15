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
    do {
      try context.save()
      rescheduleAllNotifications(context: context)
      syncEventsToWidget(context: context)
    } catch {
      ErrorPresenter.shared.present(error)
    }
  }

  func updateEvent(
    _ event: Event, title: String, notes: String?, color: String, reminderInterval: TimeInterval?,
    context: ModelContext
  ) {
    event.title = title
    event.notes = notes
    event.color = color
    event.reminderInterval = reminderInterval
    do {
      try context.save()
      rescheduleAllNotifications(context: context)
      syncEventsToWidget(context: context)
    } catch {
      ErrorPresenter.shared.present(error)
    }
  }

  func deleteEvent(_ event: Event, context: ModelContext) {
    context.delete(event)
    do {
      try context.save()
      rescheduleAllNotifications(context: context)
      syncEventsToWidget(context: context)
    } catch {
      ErrorPresenter.shared.present(error)
    }
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
    } catch {
      ErrorPresenter.shared.present(error)
    }
  }

  func syncEventsToWidget(context: ModelContext) {
    let calendar = Calendar.current
    let today = Date()

    guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return }
    let rangeStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
    let rangeEnd = calendar.date(byAdding: .day, value: 15, to: weekStart)!

    let eventDescriptor = FetchDescriptor<Event>(
      predicate: #Predicate { event in
        event.date >= rangeStart && event.date <= rangeEnd
      },
      sortBy: [SortDescriptor(\.date)]
    )

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    var eventMap: [String: [String]] = [:]

    // Sync events
    do {
      let events = try context.fetch(eventDescriptor)
      for event in events {
        let key = formatter.string(from: event.date)
        var colors = eventMap[key] ?? []
        if colors.count < 6 {
          colors.append(event.isHoliday ? "holiday:\(event.color)" : event.color)
        }
        eventMap[key] = colors
      }
    } catch {}

    // Sync todos with due dates (prefixed with "todo:" for widget differentiation)
    let todoDescriptor = FetchDescriptor<TodoItem>(
      predicate: #Predicate { todo in
        todo.isCompleted == false && todo.parentTodo == nil && todo.dueDate != nil
      }
    )

    do {
      let todos = try context.fetch(todoDescriptor)
      for todo in todos {
        guard let dueDate = todo.dueDate,
          dueDate >= rangeStart && dueDate <= rangeEnd
        else { continue }
        let key = formatter.string(from: dueDate)
        var colors = eventMap[key] ?? []
        if colors.count < 6 {
          let catColor = todo.category?.color ?? "green"
          let priKey = todo.priority  // "low", "medium", "high"
          colors.append("todo:\(catColor):\(priKey)")
        }
        eventMap[key] = colors
      }
    } catch {}

    do {
      let data = try JSONSerialization.data(withJSONObject: eventMap)
      if let jsonString = String(data: data, encoding: .utf8) {
        let defaults = UserDefaults(suiteName: "group.com.shoode.calendar")
        defaults?.set(jsonString, forKey: "widgetEventData")
        defaults?.synchronize()
      }
    } catch {
      ErrorPresenter.shared.present(error)
    }

    WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
    WidgetCenter.shared.reloadTimelines(ofKind: "CombinedWidget")
  }
}
