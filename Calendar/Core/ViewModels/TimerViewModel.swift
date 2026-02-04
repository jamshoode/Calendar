import SwiftUI
import SwiftData
import Combine
import WidgetKit

class TimerViewModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var selectedPreset: TimerPreset?
    
    private var timer: AnyCancellable?
    private var endTime: Date?
    
    func startTimer(duration: TimeInterval) {
        remainingTime = duration
        endTime = Date().addingTimeInterval(duration)
        isRunning = true
        isPaused = false
        
        UserDefaults.shared.set(true, forKey: "hasActiveTimer")
        UserDefaults.shared.synchronize()
        
        NotificationService.shared.scheduleTimerNotification(duration: duration)
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    func pauseTimer() {
        isPaused = true
        timer?.cancel()
    }
    
    func resumeTimer() {
        isPaused = false
        if let endTime = endTime {
            let newDuration = endTime.timeIntervalSince(Date())
            if newDuration > 0 {
                timer = Timer.publish(every: 0.1, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.updateTimer()
                    }
            } else {
                stopTimer()
            }
        }
    }
    
    func stopTimer() {
        isRunning = false
        isPaused = false
        remainingTime = 0
        timer?.cancel()
        timer = nil
        
        UserDefaults.shared.set(false, forKey: "hasActiveTimer")
        UserDefaults.shared.synchronize()
        
        NotificationService.shared.cancelTimerNotifications()
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
    }
    
    func resetTimer() {
        stopTimer()
        if let preset = selectedPreset {
            remainingTime = preset.duration
        }
    }
    
    private func updateTimer() {
        guard let endTime = endTime else { return }
        
        let remaining = endTime.timeIntervalSince(Date())
        if remaining <= 0 {
            remainingTime = 0
            stopTimer()
            AudioService.shared.playTimerEndSound()
        } else {
            remainingTime = remaining
        }
    }
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: Constants.Storage.appGroupIdentifier) ?? .standard
    }
}
