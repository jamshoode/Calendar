import SwiftData
import Foundation

enum TimerType: String, Codable {
    case countdown
}

@Model
class TimerSession {
    var id: UUID
    var duration: TimeInterval
    var remainingTime: TimeInterval
    var type: TimerType
    var startTime: Date?
    var isActive: Bool
    var isPaused: Bool
    
    init(duration: TimeInterval, type: TimerType = .countdown) {
        self.id = UUID()
        self.duration = duration
        self.remainingTime = duration
        self.type = type
        self.startTime = nil
        self.isActive = false
        self.isPaused = false
    }
}
