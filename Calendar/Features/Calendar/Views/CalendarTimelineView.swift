import SwiftUI

/// Timeline mode for the Calendar tab — horizontal week strip + vertical hourly axis with event blocks.
struct CalendarTimelineView: View {
  @State var selectedDate: Date
  let events: [Event]
  let onEventTap: (Event) -> Void
  let onDateSelect: (Date) -> Void
  let currentMonth: Date

  private let startHour = 0
  private let endHour = 24
  private let hourHeight: CGFloat = 56

  private var timelineEvents: [Event] {
    // Holiday events displayed as all-day; regular events on timeline
    events.filter { !$0.isHoliday }
  }

  private var allDayEvents: [Event] {
    events.filter { $0.isHoliday }
  }

  var body: some View {
    VStack(spacing: 0) {
      WeekStrip(
        selectedDate: Binding(
          get: { selectedDate },
          set: { date in
            selectedDate = date
            onDateSelect(date)
          }
        ), currentMonth: currentMonth)

      // All-day events bar
      if !allDayEvents.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 6) {
            ForEach(allDayEvents) { event in
              Text(event.title)
                .font(Typography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.eventColor(named: event.color))
                .clipShape(Capsule())
                .onTapGesture { onEventTap(event) }
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 6)
        }
        .background(Color.surfaceCard)
      }

      Divider()

      // Hourly timeline
      ScrollViewReader { proxy in
        ScrollView {
          ZStack(alignment: .topLeading) {
            // Hour grid
            VStack(spacing: 0) {
              ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                  Text(hourLabel(hour))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.textTertiary)
                    .frame(width: 44, alignment: .trailing)

                  VStack(spacing: 0) {
                    Divider()
                    Spacer()
                  }
                }
                .frame(height: hourHeight)
                .id(hour)
              }
            }

            // Event blocks
            ForEach(timelineEvents) { event in
              TimelineEventBlock(
                event: event,
                hourHeight: hourHeight,
                startHour: startHour
              )
              .onTapGesture { onEventTap(event) }
            }
          }
          .padding(.trailing, 16)
        }
        .onAppear {
          // Scroll to current hour or first event
          let targetHour = Calendar.current.component(.hour, from: Date())
          withAnimation {
            proxy.scrollTo(max(targetHour - 1, 0), anchor: .top)
          }
        }
      }
    }
  }

  private func hourLabel(_ hour: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat =
      DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)?.contains("a")
        == true ? "h a" : "HH:mm"
    var components = DateComponents()
    components.hour = hour
    let date = Calendar.current.date(from: components) ?? Date()
    formatter.locale = Locale.current
    return formatter.string(from: date)
  }
}

// MARK: - Event Block

private struct TimelineEventBlock: View {
  let event: Event
  let hourHeight: CGFloat
  let startHour: Int

  private var topOffset: CGFloat {
    let cal = Calendar.current
    let hour = cal.component(.hour, from: event.date)
    let minute = cal.component(.minute, from: event.date)
    return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
  }

  private var blockHeight: CGFloat {
    // Default 1-hour event if no end time
    max(hourHeight * 0.8, 40)
  }

  var body: some View {
    HStack(spacing: 0) {
      RoundedRectangle(cornerRadius: 3)
        .fill(Color.eventColor(named: event.color))
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 2) {
        Text(event.title)
          .font(Typography.caption)
          .fontWeight(.semibold)
          .foregroundColor(Color.textPrimary)
          .lineLimit(1)

        Text(event.date.formatted(date: .omitted, time: .shortened))
          .font(.system(size: 10))
          .foregroundColor(Color.textSecondary)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)

      Spacer()
    }
    .frame(height: blockHeight)
    .background(Color.eventColor(named: event.color).opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .padding(.leading, 60)  // After the hour label column
    .offset(y: topOffset)
  }
}
