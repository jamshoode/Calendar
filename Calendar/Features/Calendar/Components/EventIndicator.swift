import SwiftUI

struct EventIndicator: View {
  let events: [EventOccurrence]

  private var displayedEvents: [EventOccurrence] {
    Array(events.prefix(2))
  }

  var body: some View {
    VStack(spacing: 3) {
      ForEach(displayedEvents, id: \.id) { event in
        RoundedRectangle(cornerRadius: 3)
          .fill(Color.eventColor(named: event.sourceEvent.color))
          .frame(width: 30, height: 4)
      }
    }
  }
}
