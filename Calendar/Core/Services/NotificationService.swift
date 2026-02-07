import Foundation
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationService()

  private override init() {
    super.init()
    UNUserNotificationCenter.current().delegate = self
  }

  func requestAuthorization() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
      if error != nil {
        // print("Notification authorization error: \(error)")
      }
    }
  }

  func scheduleTimerNotification(duration: TimeInterval, identifier: String = "timer") {
    let content = UNMutableNotificationContent()
    content.title = "Timer Complete"
    content.body = "Your timer has finished!"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request)
  }

  func scheduleAlarmNotification(date: Date) {
    let content = UNMutableNotificationContent()
    content.title = "Alarm"
    content.body = "Your alarm is ringing!"
    content.sound = .default

    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    let request = UNNotificationRequest(identifier: "alarm", content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request)
  }

  func cancelTimerNotifications(identifier: String = "timer") {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
      identifier
    ])
  }

  func cancelAlarmNotifications() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarm"])
  }

  // MARK: - Event Notifications

  func syncEventNotifications(events: [Event]) {
    // 1. Cancel all existing event notifications to prevent duplicates/stale data
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      let eventIdentifiers =
        requests
        .filter { $0.identifier.hasPrefix("event-") }
        .map { $0.identifier }

      UNUserNotificationCenter.current().removePendingNotificationRequests(
        withIdentifiers: eventIdentifiers)

      // 2. Schedule notifications for upcoming events (limit to 50 to respect OS limits)
      // Filter: Has reminder, is in future
      let upcomingEvents =
        events
        .filter { event in
          guard let offset = event.reminderInterval, offset > 0 else { return false }
          let notifyDate = event.date.addingTimeInterval(-offset)
          return notifyDate > Date()
        }
        .sorted { $0.date < $1.date }
        .prefix(50)

      for event in upcomingEvents {
        self.scheduleEventNotification(event: event)
      }

      // print(" synced \(upcomingEvents.count) event notifications")
    }
  }

  private func scheduleEventNotification(event: Event) {
    guard let offset = event.reminderInterval, offset > 0 else { return }
    let notifyDate = event.date.addingTimeInterval(-offset)

    let content = UNMutableNotificationContent()
    content.title = event.title
    content.body = "Upcoming event at \(event.date.formatted(date: .omitted, time: .shortened))"
    content.sound = .default

    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: notifyDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let identifier = "event-\(event.id.uuidString)"

    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if error != nil {
        // print("Error scheduling event notification: \(error)")
      }
    }
  }

  func scheduleTodoNotification(todo: TodoItem) {
    guard let dueDate = todo.dueDate else { return }

    // Schedule the main reminder (before due date)
    let offset = todo.reminderInterval ?? 0
    if offset > 0 {
      let notifyDate = dueDate.addingTimeInterval(-offset)
      if notifyDate > Date() {
        let content = UNMutableNotificationContent()
        content.title = todo.title
        content.body = "Due at \(dueDate.formatted(date: .abbreviated, time: .shortened))"
        content.sound = .default

        let components = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute, .second], from: notifyDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "todo-\(todo.id.uuidString)"

        let request = UNNotificationRequest(
          identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
      }
    }

    // Schedule repeat reminders (every N minutes from start date until due date)
    if let repeatInterval = todo.reminderRepeatInterval, repeatInterval > 0 {
      scheduleRepeatReminders(todo: todo, dueDate: dueDate, repeatInterval: repeatInterval)
    }
  }

  private func scheduleRepeatReminders(
    todo: TodoItem, dueDate: Date, repeatInterval: TimeInterval
  ) {
    let now = Date()
    // Start from the due date minus some window, or from now if that's already past
    var nextFire = now > dueDate ? now : now
    // Walk forward in intervals of repeatInterval, starting from a logical point
    // We start from the nearest future interval-aligned time
    let startRef = now
    let elapsed = startRef.timeIntervalSince(startRef)
    nextFire = startRef.addingTimeInterval(
      repeatInterval - elapsed.truncatingRemainder(dividingBy: repeatInterval))

    var index = 0
    let maxNotifications = 50  // iOS limit per app is 64 total pending

    while nextFire < dueDate && index < maxNotifications {
      if nextFire > now {
        let content = UNMutableNotificationContent()
        content.title = todo.title
        content.body =
          "Reminder — due at \(dueDate.formatted(date: .abbreviated, time: .shortened))"
        content.sound = .default

        let components = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute, .second], from: nextFire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "todo-repeat-\(todo.id.uuidString)-\(index)"

        let request = UNNotificationRequest(
          identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
      }
      nextFire = nextFire.addingTimeInterval(repeatInterval)
      index += 1
    }
  }

  func cancelTodoNotification(id: UUID) {
    // Cancel main reminder
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
      "todo-\(id.uuidString)"
    ])
    // Cancel all repeat reminders for this todo
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      let repeatIds = requests.filter {
        $0.identifier.hasPrefix("todo-repeat-\(id.uuidString)")
      }.map { $0.identifier }
      if !repeatIds.isEmpty {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
          withIdentifiers: repeatIds)
      }
    }
  }

  func syncTodoNotifications(todos: [TodoItem]) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      let todoIdentifiers =
        requests
        .filter { $0.identifier.hasPrefix("todo-") }
        .map { $0.identifier }

      UNUserNotificationCenter.current().removePendingNotificationRequests(
        withIdentifiers: todoIdentifiers)

      let upcomingTodos =
        todos
        .filter { todo in
          guard let dueDate = todo.dueDate else { return false }
          let offset = todo.reminderInterval ?? 0
          let notifyDate = dueDate.addingTimeInterval(-offset)
          return notifyDate > Date()
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        .prefix(50)

      for todo in upcomingTodos {
        self.scheduleTodoNotification(todo: todo)
      }
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
