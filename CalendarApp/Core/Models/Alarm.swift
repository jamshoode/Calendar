import SwiftData
import Foundation

@Model
class Alarm {
    var id: UUID
    var time: Date
    var isEnabled: Bool
    var soundName: String
    var repeatDays: [Int]
    
    init(time: Date, soundName: String = "default") {
        self.id = UUID()
        self.time = time
        self.isEnabled = true
        self.soundName = soundName
        self.repeatDays = []
    }
}
