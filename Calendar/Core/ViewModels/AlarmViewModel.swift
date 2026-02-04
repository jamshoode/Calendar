import SwiftUI
import SwiftData

class AlarmViewModel: ObservableObject {
    @Published var alarmTime: Date = Date()
    @Published var isEnabled: Bool = false
    
    func createAlarm(time: Date, context: ModelContext) {
        let alarm = Alarm(time: time)
        context.insert(alarm)
        
        UserDefaults.shared.set(true, forKey: "hasActiveAlarm")
        UserDefaults.shared.synchronize()
        
        NotificationService.shared.scheduleAlarmNotification(date: time)
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
    }
    
    func setAlarm(time: Date) {
        alarmTime = time
        if isEnabled {
            NotificationService.shared.cancelAlarmNotifications()
            NotificationService.shared.scheduleAlarmNotification(date: time)
        }
    }
    
    func toggleAlarm(alarm: Alarm, context: ModelContext) {
        alarm.isEnabled.toggle()
        
        UserDefaults.shared.set(alarm.isEnabled, forKey: "hasActiveAlarm")
        UserDefaults.shared.synchronize()
        
        if alarm.isEnabled {
            NotificationService.shared.scheduleAlarmNotification(date: alarm.time)
        } else {
            NotificationService.shared.cancelAlarmNotifications()
        }
        
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
    }
    
    func deleteAlarm(alarm: Alarm, context: ModelContext) {
        context.delete(alarm)
        
        UserDefaults.shared.set(false, forKey: "hasActiveAlarm")
        UserDefaults.shared.synchronize()
        
        NotificationService.shared.cancelAlarmNotifications()
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
    }
    
    func timeRemainingText(for alarm: Alarm) -> String {
        let remaining = timeRemainingUntil(alarm: alarm)
        
        if remaining <= 0 {
            return "Alarm ringing now"
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 0 {
            return "Alarm in \(hours)h \(minutes)m"
        } else {
            return "Alarm in \(minutes)m"
        }
    }
    
    private func timeRemainingUntil(alarm: Alarm) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: alarm.time)
        
        guard let nextAlarm = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) else {
            return 0
        }
        
        return nextAlarm.timeIntervalSince(now)
    }
    
    var timeRemaining: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: alarmTime)
        
        guard let nextAlarm = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) else {
            return 0
        }
        
        return nextAlarm.timeIntervalSince(now)
    }
}
