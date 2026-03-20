import SwiftData
import SwiftUI

/// Timeline mode for the Calendar tab — horizontal week strip + vertical hourly axis with event blocks.
struct CalendarTimelineView: View {
  @Binding var selectedDate: Date
  let events: [EventOccurrence]
  let todos: [TodoItem]
  let expenses: [Expense]
  let onEventTap: (EventOccurrence) -> Void
  let onDateSelect: (Date) -> Void
  let currentMonth: Date

  private let startHour = 0
  private let endHour = 24
  private let hourHeight: CGFloat = 56

  private var timelineEvents: [EventOccurrence] {
    events
      .filter { !isAllDayOccurrence($0) && $0.occurrenceDate.isSameDay(as: selectedDate) }
      .sorted { $0.occurrenceDate < $1.occurrenceDate }
  }

  private var timelineExpenses: [Expense] {
    expenses
      .filter { $0.date.isSameDay(as: selectedDate) }
      .sorted { $0.date < $1.date }
  }

  private var allDayEvents: [EventOccurrence] {
    events
      .filter { isAllDayOccurrence($0) && $0.occurrenceDate.isSameDay(as: selectedDate) }
      .sorted {
        if $0.occurrenceDate != $1.occurrenceDate {
          return $0.occurrenceDate < $1.occurrenceDate
        }
        return $0.sourceEvent.title.localizedCaseInsensitiveCompare($1.sourceEvent.title)
          == .orderedAscending
      }
  }

  private var allDayTodos: [TodoItem] {
    todos
      .filter { !$0.isCompleted && ($0.dueDate?.isSameDay(as: selectedDate) ?? false) }
      .sorted {
        let lhsDue = $0.dueDate ?? .distantFuture
        let rhsDue = $1.dueDate ?? .distantFuture
        if lhsDue != rhsDue { return lhsDue < rhsDue }
        return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
      }
  }

  private var firstBusyHour: Int? {
    let calendar = Calendar.current

    let eventHours = timelineEvents.map { calendar.component(.hour, from: $0.occurrenceDate) }
    let expenseHours = timelineExpenses.map { calendar.component(.hour, from: $0.date) }
    let allHours = eventHours + expenseHours

    return allHours.min()
  }

  private var initialScrollHour: Int {
    if let firstBusyHour {
      return max(firstBusyHour - 1, startHour)
    }
    return max(Calendar.current.component(.hour, from: Date()) - 1, startHour)
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

      Divider()

      if !allDayEvents.isEmpty || !allDayTodos.isEmpty {
        AllDayEventsRow(events: allDayEvents, todos: allDayTodos, onEventTap: onEventTap)
        Divider()
      }

      // Hourly timeline
      ScrollViewReader { proxy in
        ScrollView(showsIndicators: false) {
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

            // Expense blocks
            ForEach(timelineExpenses) { expense in
              TimelineExpenseBlock(
                expense: expense,
                hourHeight: hourHeight,
                startHour: startHour
              )
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
          withAnimation {
            proxy.scrollTo(initialScrollHour, anchor: .top)
          }
        }
        .onChange(of: selectedDate) { _, _ in
          withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(initialScrollHour, anchor: .top)
          }
        }
      }
      .gesture(
        DragGesture()
          .onEnded { value in
            let threshold: CGFloat = 50
            if value.translation.width < -threshold {
              // Swipe Left -> Next Day
              moveDay(by: 1)
            } else if value.translation.width > threshold {
              // Swipe Right -> Previous Day
              moveDay(by: -1)
            }
          }
      )
    }
  }

  private func moveDay(by offset: Int) {
    if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
      withAnimation {
        selectedDate = newDate
        onDateSelect(newDate)
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

  private func isAllDayOccurrence(_ occurrence: EventOccurrence) -> Bool {
    let source = occurrence.sourceEvent
    if source.isAllDay || source.isHoliday {
      return true
    }
    guard let externalCalendarId = source.externalCalendarId else {
      return false
    }
    return GoogleCalendarSyncService.isGoogleHolidayCalendarId(externalCalendarId)
  }
}

private struct AllDayEventsRow: View {
  let events: [EventOccurrence]
  let todos: [TodoItem]
  let onEventTap: (EventOccurrence) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 4) {
      Text(Localization.string(.allDay))
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(Color.textTertiary)
        .frame(width: 56, alignment: .trailing)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.top, 10)

      VStack(alignment: .leading, spacing: 6) {
        ForEach(events) { event in
          AllDayEventPill(event: event)
            .onTapGesture { onEventTap(event) }
        }

        ForEach(todos) { todo in
          AllDayTodoPill(todo: todo)
        }
      }
      .padding(.vertical, 8)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 8)
    .background(Color.backgroundTertiary.opacity(0.2))
  }
}

private struct AllDayTodoPill: View {
  let todo: TodoItem

  private var priorityColor: Color {
    switch todo.priorityEnum {
    case .high: return .priorityHigh
    case .medium: return .priorityMedium
    case .low: return .priorityLow
    }
  }

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "checklist")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(priorityColor)

      Text(todo.title)
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color.textPrimary)
        .lineLimit(1)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(priorityColor.opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

private struct AllDayEventPill: View {
  let event: EventOccurrence

  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(Color.eventColor(named: event.sourceEvent.color))
        .frame(width: 7, height: 7)

      Text(event.sourceEvent.title)
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color.textPrimary)
        .lineLimit(1)

      Spacer(minLength: 0)

      if event.sourceEvent.isHoliday {
        Image(systemName: "star.fill")
          .font(.system(size: 10, weight: .bold))
          .foregroundColor(Color.eventTeal)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.eventColor(named: event.sourceEvent.color).opacity(0.14))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - Event Block

private struct TimelineEventBlock: View {
  let event: EventOccurrence
  let hourHeight: CGFloat
  let startHour: Int

  private var topOffset: CGFloat {
    let cal = Calendar.current
    let hour = cal.component(.hour, from: event.occurrenceDate)
    let minute = cal.component(.minute, from: event.occurrenceDate)
    return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
  }

  private var blockHeight: CGFloat {
    // Default 1-hour event if no end time
    max(hourHeight * 0.8, 40)
  }

  var body: some View {
    HStack(spacing: 0) {
      RoundedRectangle(cornerRadius: 3)
        .fill(Color.eventColor(named: event.sourceEvent.color))
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 2) {
        Text(event.sourceEvent.title)
          .font(Typography.caption)
          .fontWeight(.semibold)
          .foregroundColor(Color.textPrimary)
          .lineLimit(1)

        Text(event.occurrenceDate.formatted(date: .omitted, time: .shortened))
          .font(.system(size: 10))
          .foregroundColor(Color.textSecondary)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)

      Spacer()
    }
    .frame(height: blockHeight)
    .background(Color.eventColor(named: event.sourceEvent.color).opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .padding(.leading, 60)  // After the hour label column
    .padding(.trailing, 12)
    .offset(y: topOffset)
  }
}

private struct TimelineExpenseBlock: View {
  let expense: Expense
  let hourHeight: CGFloat
  let startHour: Int

  private var topOffset: CGFloat {
    let cal = Calendar.current
    let hour = cal.component(.hour, from: expense.date)
    let minute = cal.component(.minute, from: expense.date)
    return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
  }

  private var blockHeight: CGFloat {
    // Default size for expense block
    max(hourHeight * 0.6, 30)
  }

  var body: some View {
    HStack(spacing: 0) {
      RoundedRectangle(cornerRadius: 3)
        .fill(Color.orange)
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 2) {
        Text(expense.title)
          .font(Typography.caption)
          .fontWeight(.semibold)
          .foregroundColor(Color.textPrimary)
          .lineLimit(1)

        Text(expense.amount.formatted(.currency(code: expense.currency)))
          .font(.system(size: 10))
          .foregroundColor(Color.textSecondary)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)

      Spacer()
    }
    .frame(height: blockHeight)
    .background(Color.orange.opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .padding(.leading, 60)  // After the hour label column
    .padding(.trailing, 12)
    .offset(y: topOffset)
  }
}
