import SwiftData
import Foundation

@Model
class TimerPreset {
    var id: UUID
    var duration: TimeInterval
    var label: String
    var icon: String
    var order: Int
    
    init(duration: TimeInterval, label: String, icon: String, order: Int) {
        self.id = UUID()
        self.duration = duration
        self.label = label
        self.icon = icon
        self.order = order
    }
    
    static let defaultPresets: [TimerPreset] = [
        TimerPreset(duration: 60, label: "1 min", icon: "timer", order: 0),
        TimerPreset(duration: 300, label: "5 min", icon: "timer", order: 1),
        TimerPreset(duration: 600, label: "10 min", icon: "timer", order: 2),
        TimerPreset(duration: 900, label: "15 min", icon: "timer", order: 3),
        TimerPreset(duration: 1200, label: "20 min", icon: "timer", order: 4),
        TimerPreset(duration: 1800, label: "30 min", icon: "timer", order: 5),
        TimerPreset(duration: 2700, label: "45 min", icon: "timer", order: 6),
        TimerPreset(duration: 3600, label: "60 min", icon: "timer", order: 7)
    ]
}
