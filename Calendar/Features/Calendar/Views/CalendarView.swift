import SwiftData
import SwiftUI
import Foundation

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
  @State private var showingSettings = false
  @State private var editingEvent: Event?
  @State private var editingTodo: TodoItem?
  @State private var detailEvent: Event?

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        // Month Navigation Header
        MonthHeaderView(
          currentMonth: viewModel.currentMonth,
          viewMode: $viewMode,
          onPrevious: viewModel.moveToPreviousMonth,
          onNext: viewModel.moveToNextMonth,
          onAdd: { showingAddEvent = true },
          onSettings: { showingSettings = true },
          onTitleTap: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              showingDatePicker.toggle()
            }
          }
        )
        .padding(.top, 10)
        .animation(nil, value: viewMode)

        // View Mode Content
        VStack(spacing: 0) {
            switch viewMode {
            case .grid:
              VStack(spacing: 4) {
                  WeekdayHeaderView()
                      .padding(.top, 16)
                  
                  MonthView(
                    currentMonth: viewModel.currentMonth,
                    selectedDate: viewModel.selectedDate,
                    events: eventsForMonth,
                    todos: todosForMonth,
                    onSelectDate: { date in
                      let selectedMonth = Calendar.current.component(.month, from: date)
                      let currentMonth = Calendar.current.component(.month, from: viewModel.currentMonth)
                      if selectedMonth != currentMonth {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                          viewModel.currentMonth = date
                        }
                      }
                      viewModel.selectDate(date)
                      if showingDatePicker {
                        withAnimation { showingDatePicker = false }
                      }
                    }
                  )
                  .frame(height: 310) // 6 rows with tighter spacing
                  
                  Spacer(minLength: 0)
                  
                  EventListView(
                    date: viewModel.selectedDate ?? Date(),
                    events: eventsForSelectedDate,
                    todos: todosForSelectedDate,
                    onEdit: { event in detailEvent = event },
                    onDelete: { event in
                      guard !event.isHoliday else { return }
                      deleteEvent(event)
                    },
                    onAdd: { showingAddEvent = true },
                    onTodoToggle: { todo in
                      todoViewModel.toggleCompletion(todo, context: modelContext)
                    },
                    onTodoTap: { todo in editingTodo = todo },
                    showJumpToToday: !Calendar.current.isDateInToday(viewModel.selectedDate ?? Date())
                      || !Calendar.current.isDate(viewModel.currentMonth, equalTo: Date(), toGranularity: .month),
                    onJumpToToday: {
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        let today = Date()
                        viewModel.selectDate(today)
                        viewModel.currentMonth = today
                      }
                    }
                  )
                  .padding(.bottom, 100) // Space from floating tab bar
              }
              .gesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                  .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    // Only trigger if horizontal swipe is dominant
                    guard abs(horizontal) > abs(vertical) else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                      if horizontal < 0 {
                        viewModel.moveToNextMonth()
                      } else {
                        viewModel.moveToPreviousMonth()
                      }
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
                selectedDate: Binding(
                  get: { viewModel.selectedDate ?? Date() },
                  set: { viewModel.selectedDate = $0 }
                ),
                events: eventsForSelectedDate,
                onEventTap: { event in detailEvent = event },
                onDateSelect: { date in viewModel.selectDate(date) },
                currentMonth: viewModel.currentMonth
              )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .blur(radius: showingDatePicker ? 4 : 0)
      
      // Overlays (DatePicker, Popover etc)
      if showingDatePicker {
          Color.black.opacity(0.1)
              .ignoresSafeArea()
              .onTapGesture { showingDatePicker = false }
          
          MonthYearPicker(currentMonth: $viewModel.currentMonth, isPresented: $showingDatePicker)
              .transition(.scale.combined(with: .opacity))
              .zIndex(1)
      }
    }
    .navigationBarHidden(true) // We use custom header
    .sheet(isPresented: $showingAddEvent) {
      AddEventView(date: viewModel.selectedDate ?? Date()) {
        title, notes, color, date, reminderInterval in
        addEvent(title: title, notes: notes, color: color, date: date, reminderInterval: reminderInterval)
      }
    }
    .sheet(isPresented: $showingSettings) {
      SettingsSheet(isPresented: $showingSettings)
    }
    .sheet(item: $editingEvent) { event in
      AddEventView(
        date: event.date,
        event: event,
        onSave: { title, notes, color, date, reminderInterval in
          eventViewModel.updateEvent(
            event,
            title: title,
            notes: notes,
            color: color,
            reminderInterval: reminderInterval,
            context: modelContext
          )
        },
        onDelete: {
          deleteEvent(event)
        }
      )
    }
    .overlay {
      if let event = detailEvent {
        ZStack {
          Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
              detailEvent = nil
            }
          
          EventDetailPopover(
            event: event,
            onDismiss: { detailEvent = nil },
            onEdit: {
              detailEvent = nil
              editingEvent = event
            },
            onDelete: {
              detailEvent = nil
              deleteEvent(event)
            }
          )
        }
      }
    }
  }

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

  private func addEvent(title: String, notes: String?, color: String, date: Date, reminderInterval: TimeInterval?) {
    eventViewModel.addEvent(date: date, title: title, notes: notes, color: color, reminderInterval: reminderInterval, context: modelContext)
  }

  private func deleteEvent(_ event: Event) {
    eventViewModel.deleteEvent(event, context: modelContext)
  }

  private let eventViewModel = EventViewModel()
}

struct WeekdayHeaderView: View {
    private var adjustedWeekdays: [String] {
        let symbols = Calendar.current.veryShortWeekdaySymbols // [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
        var week = symbols
        let first = week.removeFirst()
        week.append(first) // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
        return week
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(adjustedWeekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct MonthHeaderView: View {
  let currentMonth: Date
  @Binding var viewMode: CalendarViewMode
  let onPrevious: () -> Void
  let onNext: () -> Void
  let onAdd: () -> Void
  let onSettings: () -> Void
  var onTitleTap: (() -> Void)? = nil

  var body: some View {
    VStack(spacing: 8) {
      HStack(alignment: .center) {
        Button(action: onSettings) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.textSecondary)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .glassHalo(cornerRadius: 100)
        }
        .buttonStyle(.plain)

        Spacer()

        Button(action: { onTitleTap?() }) {
          HStack(spacing: 4) {
            Text(currentMonth.formattedMonthYear.localizedCapitalized)
              .font(.system(size: 20, weight: .black, design: .rounded))
              .foregroundColor(Color.textPrimary)
            
            Image(systemName: "chevron.down")
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(Color.accentColor)
          }
        }
        .buttonStyle(.plain)

        Spacer()
        
        Button(action: onAdd) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)

      HStack {
        HStack(spacing: 4) {
          Button(action: onPrevious) {
            Image(systemName: "chevron.left")
              .font(.system(size: 12, weight: .bold))
              .frame(width: 28, height: 28)
              .background(.ultraThinMaterial)
              .clipShape(Circle())
          }
          .buttonStyle(.plain)
          
          Button(action: onNext) {
            Image(systemName: "chevron.right")
              .font(.system(size: 12, weight: .bold))
              .frame(width: 28, height: 28)
              .background(.ultraThinMaterial)
              .clipShape(Circle())
          }
          .buttonStyle(.plain)
        }
        
        Spacer()
        
        HStack(spacing: 4) {
          ForEach(CalendarViewMode.allCases, id: \.self) { mode in
            Button {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewMode = mode
              }
            } label: {
              Image(systemName: mode.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(viewMode == mode ? .white : Color.textSecondary)
                .frame(width: 32, height: 28)
                .background(viewMode == mode ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal, 20)
    }
  }
}
