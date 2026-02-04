import SwiftUI
import SwiftData

class AlarmViewModel: ObservableObject {
    @Published var alarmTime: Date = Date()
    @Published var isEnabled: Bool = false
    
    func setAlarm(time: Date) {
        alarmTime = time
        if isEnabled {
            NotificationService.shared.cancelAlarmNotifications()
            NotificationService.shared.scheduleAlarmNotification(date: time)
        }
    }
    
    func toggleAlarm() {
        isEnabled.toggle()
        
        if isEnabled {
            NotificationService.shared.scheduleAlarmNotification(date: alarmTime)
        } else {
            NotificationService.shared.cancelAlarmNotifications()
        }
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
