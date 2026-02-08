import SwiftData
import SwiftUI

// MARK: - View Mode

enum CalendarViewMode: String, CaseIterable {
  case grid, list, timeline

  var icon: String {
    switch self {
    case .grid: return "square.grid.2x2"
    case .list: return "list.bullet"
    case .timeline: return "clock"
    }
  }
}

struct CalendarView: View {
  @StateObject private var viewModel = CalendarViewModel()
  @StateObject private var todoViewModel = TodoViewModel()
  @Query(sort: \Event.date) private var events: [Event]
  @Query(
    filter: #Predicate<TodoItem> { $0.parentTodo == nil && $0.dueDate != nil },
    sort: \TodoItem.dueDate)
  private var todosWithDueDate: [TodoItem]
  @Environment(\.modelContext) private var modelContext

  @State private var viewMode: CalendarViewMode = .grid
  @State private var showingAddEvent = false
  @State private var showingDatePicker = false
  @State private var editingEvent: Event?
  @State private var editingTodo: TodoItem?
  @State private var detailEvent: Event?

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
        // Month Navigation Header with view-mode toggle
        MonthHeaderView(
          currentMonth: viewModel.currentMonth,
          viewMode: $viewMode,
          onPrevious: viewModel.moveToPreviousMonth,
          onNext: viewModel.moveToNextMonth,
          onTitleTap: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              showingDatePicker.toggle()
            }
          }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          Localization.string(.calendarFor(viewModel.currentMonth.formattedMonthYear)))

        // Weekday Labels (for grid mode)
        if viewMode == .grid {
          WeekdayHeaderView()
            .padding(.top, 8)
        }

        // View Mode Content
        switch viewMode {
        case .grid:
          // Calendar Grid - Fixed height for 6 rows
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
          .frame(height: 288)
          .swipeGesture(
            onLeft: viewModel.moveToNextMonth,
            onRight: viewModel.moveToPreviousMonth
          )
          .accessibilityHint("Swipe left or right to change months")

          // Event List Section
          EventListView(
            date: viewModel.selectedDate ?? Date(),
            events: eventsForSelectedDate,
            todos: todosForSelectedDate,
            onEdit: { event in
              detailEvent = event
            },
            onDelete: { event in
              guard !event.isHoliday else { return }
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
            },
            showJumpToToday: !Calendar.current.isDateInToday(viewModel.selectedDate ?? Date())
              || !Calendar.current.isDate(
                viewModel.currentMonth, equalTo: Date(), toGranularity: .month),
            onJumpToToday: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                let today = Date()
                viewModel.selectDate(today)
                viewModel.currentMonth = today
              }
            }
          )

        case .list:
          CalendarListView(
            currentMonth: viewModel.currentMonth,
            events: eventsForMonth,
            todos: todosForMonth,
            onEventTap: { event in detailEvent = event },
            onDateSelect: { date in viewModel.selectDate(date) }
          )

        case .timeline:
          CalendarTimelineView(
            selectedDate: viewModel.selectedDate ?? Date(),
            events: eventsForSelectedDate,
            onEventTap: { event in detailEvent = event },
            onDateSelect: { date in viewModel.selectDate(date) },
            currentMonth: viewModel.currentMonth
          )
        }
      }
      .blur(radius: showingDatePicker ? 4 : 0)
      .disabled(showingDatePicker)

      // Date Picker Overlay
      if showingDatePicker {
        Color.backgroundScrim
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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

      // Event Detail Floating Window
      if let event = detailEvent {
        Color.backgroundScrim
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
              detailEvent = nil
            }
          }
          .zIndex(3)

        EventDetailPopover(
          event: event,
          onDismiss: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
              detailEvent = nil
            }
          },
          onEdit: event.isHoliday
            ? nil
            : {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                detailEvent = nil
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                editingEvent = event
              }
            },
          onDelete: event.isHoliday
            ? nil
            : {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                detailEvent = nil
              }
              deleteEvent(event)
            }
        )
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .zIndex(4)
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: detailEvent?.id)
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
  @Binding var viewMode: CalendarViewMode
  let onPrevious: () -> Void
  let onNext: () -> Void
  var onTitleTap: (() -> Void)? = nil

  var body: some View {
    VStack(spacing: 8) {
      // Top row: Large title + view mode icons
      HStack(alignment: .firstTextBaseline) {
        Button(action: { onTitleTap?() }) {
          HStack(spacing: 6) {
            Text(currentMonth.formattedMonthYear)
              .font(Typography.largeTitle)
              .foregroundColor(Color.textPrimary)

            if onTitleTap != nil {
              Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.textTertiary)
            }
          }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isHeader)

        Spacer()

        // View mode toggle
        HStack(spacing: 4) {
          ForEach(CalendarViewMode.allCases, id: \.self) { mode in
            Button {
              withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = mode
              }
            } label: {
              Image(systemName: mode.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(viewMode == mode ? Color.textPrimary : Color.textTertiary)
                .frame(width: 32, height: 32)
                .background(viewMode == mode ? Color.secondaryFill : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
          }
        }
      }

      // Bottom row: month nav arrows
      HStack(spacing: 0) {
        Button(action: onPrevious) {
          Image(systemName: "chevron.left")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color.textSecondary)
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.string(.previousMonth))

        Spacer()

        Button(action: onNext) {
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color.textSecondary)
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.string(.nextMonth))
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }
}

struct WeekdayHeaderView: View {
  private var weekdays: [String] {
    var calendar = Calendar.current
    calendar.locale = Localization.locale
    let symbols = calendar.shortStandaloneWeekdaySymbols
    // Monday-start: shift Sunday to end
    return Array(symbols.dropFirst()) + [symbols.first!]
  }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(weekdays, id: \.self) { day in
        Text(day.prefix(3).uppercased())
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
  }
}
