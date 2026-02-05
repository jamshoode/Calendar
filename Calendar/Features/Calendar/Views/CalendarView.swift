import SwiftData
import SwiftUI

struct CalendarView: View {
  @StateObject private var viewModel = CalendarViewModel()
  @StateObject private var todoViewModel = TodoViewModel()
  @Query(sort: \Event.date) private var events: [Event]
  @Query(filter: #Predicate<TodoItem> { $0.parentTodo == nil && $0.dueDate != nil }, sort: \TodoItem.dueDate)
  private var todosWithDueDate: [TodoItem]
  @Environment(\.modelContext) private var modelContext

  @State private var showingAddEvent = false
  @State private var showingDatePicker = false
  @State private var editingEvent: Event?
  @State private var editingTodo: TodoItem?

  private var eventsForMonth: [Event] {
    let startOfMonth = viewModel.currentMonth.startOfMonth
    let endOfMonth = viewModel.currentMonth.endOfMonth
    return events.filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
  }
  
  private var todosForMonth: [TodoItem] {
    let startOfMonth = viewModel.currentMonth.startOfMonth
    let endOfMonth = viewModel.currentMonth.endOfMonth
    return todosWithDueDate.filter { todo in
      guard let dueDate = todo.dueDate else { return false }
      return dueDate >= startOfMonth && dueDate <= endOfMonth
    }
  }

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        MonthHeaderView(
          currentMonth: viewModel.currentMonth,
          onPrevious: viewModel.moveToPreviousMonth,
          onNext: viewModel.moveToNextMonth,
          onTitleTap: {
            withAnimation {
              showingDatePicker.toggle()
            }
          }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          Localization.string(.calendarFor(viewModel.currentMonth.formattedMonthYear)))

        WeekdayHeaderView()

        MonthView(
          currentMonth: viewModel.currentMonth,
          selectedDate: viewModel.selectedDate,
          events: eventsForMonth,
          todos: todosForMonth,
          onSelectDate: { date in
            viewModel.selectDate(date)
            if showingDatePicker {
              withAnimation { showingDatePicker = false }
            }
          }
        )
        .swipeGesture(
          onLeft: viewModel.moveToNextMonth,
          onRight: viewModel.moveToPreviousMonth
        )
        .accessibilityHint("Swipe left or right to change months")

        EventListView(
          date: viewModel.selectedDate ?? Date(),
          events: eventsForSelectedDate,
          todos: todosForSelectedDate,
          onEdit: { event in
            editingEvent = event
          },
          onDelete: { event in
            deleteEvent(event)
          },
          onAdd: {
            showingAddEvent = true
          },
          onTodoToggle: { todo in
            todoViewModel.toggleCompletion(todo, context: modelContext)
          },
          onTodoTap: { todo in
            editingTodo = todo
          }
        )

      }
      .padding(.top, 16)
      .padding(.bottom, 12)
      .blur(radius: showingDatePicker ? 4 : 0)
      .disabled(showingDatePicker)

      if showingDatePicker {
        Color.black.opacity(0.3)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation {
              showingDatePicker = false
            }
          }

        MonthYearPicker(
          currentMonth: $viewModel.currentMonth,
          isPresented: $showingDatePicker
        )
        .transition(.scale.combined(with: .opacity))
        .zIndex(1)
      }

      // Floating "Jump to Today" Button
      if !Calendar.current.isDateInToday(viewModel.selectedDate ?? Date())
        || !Calendar.current.isDate(viewModel.currentMonth, equalTo: Date(), toGranularity: .month)
      {
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button(action: {
              withAnimation {
                let today = Date()
                viewModel.selectDate(today)
                viewModel.currentMonth = today
              }
            }) {
              HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                  .font(.system(size: 14, weight: .bold))
                Text("Today")
                  .font(.system(size: 14, weight: .semibold))
              }
              .foregroundColor(.primary)
              .padding(.horizontal, 16)
              .padding(.vertical, 10)
              .glassBackground(cornerRadius: 30)
              .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .transition(.move(edge: .trailing).combined(with: .opacity))
          }
        }
        .zIndex(2)  // Ensure it floats above everything
      }
    }
    // Prevent layout animations on the entire VStack when selectedDate changes
    .animation(nil, value: viewModel.selectedDate)
    .animation(.easeInOut(duration: 0.2), value: viewModel.currentMonth)
    .sheet(isPresented: $showingAddEvent) {
      AddEventView(date: viewModel.selectedDate ?? Date()) {
        title, notes, color, date, reminderInterval in
        addEvent(
          title: title, notes: notes, color: color, date: date, reminderInterval: reminderInterval)
      }
    }
    .sheet(item: $editingEvent) { event in
      AddEventView(
        date: event.date,
        event: event,
        onSave: { title, notes, color, date, reminderInterval in
          updateEvent(
            event, title: title, notes: notes, color: color, date: date,
            reminderInterval: reminderInterval)
        },
        onDelete: {
          deleteEvent(event)
        }
      )
    }
    .toolbar {
      #if os(iOS)
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { showingAddEvent = true }) {
            Image(systemName: "plus")
          }
          .accessibilityLabel(Localization.string(.addEvent))
        }
      #else
        ToolbarItem(placement: .primaryAction) {
          Button(action: { showingAddEvent = true }) {
            Image(systemName: "plus")
          }
          .accessibilityLabel(Localization.string(.addEvent))
        }
      #endif
    }
    .onAppear {
      eventViewModel.rescheduleAllNotifications(context: modelContext)
    }
  }

  private var eventsForSelectedDate: [Event] {
    let dateToCheck = viewModel.selectedDate ?? Date()
    return events.filter { $0.date.isSameDay(as: dateToCheck) }
  }
  
  private var todosForSelectedDate: [TodoItem] {
    let dateToCheck = viewModel.selectedDate ?? Date()
    return todosWithDueDate.filter { todo in
      guard let dueDate = todo.dueDate else { return false }
      return dueDate.isSameDay(as: dateToCheck)
    }
  }

  private func addEvent(
    title: String, notes: String?, color: String, date: Date, reminderInterval: TimeInterval?
  ) {
    eventViewModel.addEvent(
      date: date,
      title: title,
      notes: notes,
      color: color,
      reminderInterval: reminderInterval,
      context: modelContext
    )
  }

  private func updateEvent(
    _ event: Event, title: String, notes: String?, color: String, date: Date,
    reminderInterval: TimeInterval?
  ) {
    // Since date might change, we might need a better update flow, but for now we update specific fields
    event.date = date  // Update date
    eventViewModel.updateEvent(
      event,
      title: title,
      notes: notes,
      color: color,
      reminderInterval: reminderInterval,
      context: modelContext
    )
  }

  private func deleteEvent(_ event: Event) {
    eventViewModel.deleteEvent(event, context: modelContext)
  }

  private let eventViewModel = EventViewModel()
}

struct MonthHeaderView: View {
  let currentMonth: Date
  let onPrevious: () -> Void
  let onNext: () -> Void
  var onTitleTap: (() -> Void)? = nil

  var body: some View {
    HStack {
      Button(action: onPrevious) {
        Image(systemName: "chevron.left")
          .font(.title2)
          .foregroundColor(.primary)
      }
      .accessibilityLabel(Localization.string(.previousMonth))

      Spacer()

      Button(action: { onTitleTap?() }) {
        HStack(spacing: 4) {
          Text(currentMonth.formattedMonthYear)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.primary)

          if onTitleTap != nil {
            Image(systemName: "chevron.down")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
      .accessibilityAddTraits(.isHeader)

      Spacer()

      Button(action: onNext) {
        Image(systemName: "chevron.right")
          .font(.title2)
          .foregroundColor(.primary)
      }
      .accessibilityLabel(Localization.string(.nextMonth))
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .glassBackground(cornerRadius: 16)
    .padding(.horizontal)
    .padding(.top, 8)
  }
}

struct WeekdayHeaderView: View {
  private var weekdays: [String] {
    var calendar = Calendar.current
    calendar.locale = Localization.locale
    // Adjust to match "Mon...Sun" order or system order.
    // Our sample code has Mon-Sun hardcoded effectively.
    // Let's rely on formatter.shortStandaloneWeekdaySymbols
    let symbols = calendar.shortStandaloneWeekdaySymbols
    // Default symbols usually start Sunday.
    // If we want Mon-Sun:
    // This is complex to get perfectly right for "Mon...Sun" if the UI expects exactly that order.
    // But for simplicity and correctness in UA/EN, UA usually starts Monday. EN/US starts Sunday.
    // However, the previous code hardcoded Mon...Sun.
    // If I switch to locale based, the order might change (Sun..Sat).
    // If the grid (MonthView) expects Mon-Start, I must ensure this array matches Mon-Start.
    // Let's assume Mon-Start for visual consistency with previous design if it was 7 columns fixed.
    // Shifting Sunday to end:
    return Array(symbols.dropFirst()) + [symbols.first!]
  }

  var body: some View {
    HStack {
      ForEach(weekdays, id: \.self) { day in
        Text(day)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 8)
  }
}
