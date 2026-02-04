import SwiftUI
import SwiftData
import Combine

class EventViewModel: ObservableObject {
    @Published var dummy: Bool = false
    func addEvent(date: Date, title: String, notes: String?, color: String, context: ModelContext) {
        let event = Event(date: date, title: title, notes: notes, color: color)
        context.insert(event)
    }
    
    func updateEvent(_ event: Event, title: String, notes: String?, color: String, context: ModelContext) {
        event.title = title
        event.notes = notes
        event.color = color
    }
    
    func deleteEvent(_ event: Event, context: ModelContext) {
        context.delete(event)
    }
}
