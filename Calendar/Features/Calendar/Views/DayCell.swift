import SwiftUI

struct DayCell: View {
  let date: Date
  let isCurrentMonth: Bool
  let isSelected: Bool
  let isToday: Bool
  let events: [Event]
  var todos: [TodoItem] = []

  var body: some View {
    VStack(spacing: 2) {
      Text(date.formattedDay)
        .font(.system(size: 15, weight: isToday ? .bold : .medium))
        .foregroundColor(textColor)
        .frame(width: 34, height: 34)
        .background(
          Circle()
            .fill(backgroundColor)
        )
        .overlay(
          Circle()
            .strokeBorder(isToday && !isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )

      HStack(spacing: 2) {
        if !events.isEmpty {
          EventIndicator(events: events)
        }

        if !todos.isEmpty {
          TodoIndicator(count: todos.count)
        }
      }
      .frame(height: 8)
    }
    .frame(height: 44)
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
    .opacity(isCurrentMonth ? 1.0 : 0.3)
  }

  private var backgroundColor: Color {
    isSelected ? .accentColor : .clear
  }

  private var textColor: Color {
    if isSelected {
      return .white
    } else if isToday {
      return .accentColor
    } else {
      return Color.textPrimary
    }
  }
}

struct TodoIndicator: View {
  let count: Int

  var body: some View {
    Circle()
      .fill(Color.statusInProgress)
      .frame(width: 6, height: 6)
  }
}
