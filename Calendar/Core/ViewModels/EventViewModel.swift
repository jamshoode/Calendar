import SwiftUI
import SwiftData

class EventViewModel {
    func addEvent(date: Date, title: String, notes: String?, color: String, reminderInterval: TimeInterval?, context: ModelContext) {
        let event = Event(date: date, title: title, notes: notes, color: color, reminderInterval: reminderInterval)
        context.insert(event)
        try? context.save()
        rescheduleAllNotifications(context: context)
    }
    
    func updateEvent(_ event: Event, title: String, notes: String?, color: String, reminderInterval: TimeInterval?, context: ModelContext) {
        event.title = title
        event.notes = notes
        event.color = color
        event.reminderInterval = reminderInterval
        try? context.save()
        rescheduleAllNotifications(context: context)
    }
    
    func deleteEvent(_ event: Event, context: ModelContext) {
        context.delete(event)
        try? context.save()
        rescheduleAllNotifications(context: context)
    }
    
    func rescheduleAllNotifications(context: ModelContext) {
        // Fetch all future events
        let now = Date()
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { $0.date > now },
            sortBy: [SortDescriptor(\.date)]
        )
        
        do {
            let events = try context.fetch(descriptor)
            NotificationService.shared.syncEventNotifications(events: events)
        } catch {
            // print("Failed to fetch events for notification sync: \(error)")
        }
    }
}
