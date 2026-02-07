import SwiftUI

struct MonthView: View {
  let currentMonth: Date
  let selectedDate: Date?
  let events: [Event]
  var todos: [TodoItem] = []
  let onSelectDate: (Date) -> Void

  private let calendar = Calendar.current
  private let daysInWeek = 7
  private let totalRows = 6  // Always 6 rows for consistent layout

  private var days: [Date?] {
    let startOfMonth = currentMonth.startOfMonth
    let endOfMonth = currentMonth.endOfMonth

    let firstWeekday = calendar.component(.weekday, from: startOfMonth)
    let adjustedFirstWeekday = (firstWeekday + 5) % 7

    var days: [Date?] = Array(repeating: nil, count: adjustedFirstWeekday)

    var currentDate = startOfMonth
    while currentDate <= endOfMonth {
      days.append(currentDate)
      currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
    }

    // Always pad to exactly 42 cells (6 rows × 7 days) for consistent layout
    let totalCells = totalRows * daysInWeek
    let remainingCells = totalCells - days.count
    if remainingCells > 0 {
      days.append(contentsOf: Array(repeating: nil, count: remainingCells))
    }

    return days
  }

  var body: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: daysInWeek), spacing: 4
    ) {
      ForEach(Array(days.enumerated()), id: \.offset) { index, date in
        if let date = date {
          let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
          let isSelected = selectedDate != nil && date.isSameDay(as: selectedDate!)
          let isToday = date.isToday
          let dayEvents = eventsForDate(date)
          let dayTodos = todosForDate(date)

          DayCell(
            date: date,
            isCurrentMonth: isCurrentMonth,
            isSelected: isSelected,
            isToday: isToday,
            events: dayEvents,
            todos: dayTodos
          )
          .onTapGesture {
            onSelectDate(date)
          }
        } else {
          Color.clear
            .frame(height: 44)
        }
      }
    }
    .padding(.horizontal, 12)
  }

  private func eventsForDate(_ date: Date) -> [Event] {
    events.filter { $0.date.isSameDay(as: date) }
  }

  private func todosForDate(_ date: Date) -> [TodoItem] {
    todos.filter { todo in
      guard let dueDate = todo.dueDate else { return false }
      return dueDate.isSameDay(as: date) && !todo.isCompleted
    }
  }
}
