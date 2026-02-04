import SwiftUI

struct EventIndicator: View {
    let events: [Event]
    
    private var displayedEvents: [Event] {
        Array(events.prefix(3))
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(displayedEvents, id: \.id) { event in
                Circle()
                    .fill(Color.eventColor(named: event.color))
                    .frame(width: 5, height: 5)
            }
        }
    }
}
