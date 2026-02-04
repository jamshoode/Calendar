import UserNotifications
import Foundation

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAlarmNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarm"])
    }
    
    // MARK: - Event Notifications
    
    func syncEventNotifications(events: [Event]) {
        // 1. Cancel all existing event notifications to prevent duplicates/stale data
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eventIdentifiers = requests
                .filter { $0.identifier.hasPrefix("event-") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: eventIdentifiers)
            
            // 2. Schedule notifications for upcoming events (limit to 50 to respect OS limits)
            // Filter: Has reminder, is in future
            let upcomingEvents = events
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
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notifyDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "event-\(event.id.uuidString)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                // print("Error scheduling event notification: \(error)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
