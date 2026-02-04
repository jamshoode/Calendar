import SwiftData
import Foundation

@Model
class Event {
    var id: UUID
    var date: Date
    var title: String
    var notes: String?
    var color: String
    var createdAt: Date
    
    init(date: Date, title: String, notes: String? = nil, color: String = "blue") {
        self.id = UUID()
        self.date = date
        self.title = title
        self.notes = notes
        self.color = color
        self.createdAt = Date()
    }
}
