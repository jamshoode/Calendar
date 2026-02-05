import SwiftUI

struct DayCell: View {
  let date: Date
  let isCurrentMonth: Bool
  let isSelected: Bool
  let isToday: Bool
  let events: [Event]
  var todos: [TodoItem] = []

  var body: some View {
    VStack(spacing: 4) {
      Text(date.formattedDay)
        .font(.system(size: 16, weight: isToday ? .bold : .regular))
        .foregroundColor(textColor)
        .frame(width: 32, height: 32)
        .background(
          Circle()
            .fill(
              isSelected
                ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.2) : Color.clear))
        )

      HStack(spacing: 2) {
        if !events.isEmpty {
          EventIndicator(events: events)
        }

        if !todos.isEmpty {
          TodoIndicator(count: todos.count)
        }
      }
    }
    .frame(height: 50)
    .opacity(isCurrentMonth ? 1.0 : 0.4)
  }

  private var textColor: Color {
    if isSelected {
      return .white
    } else if isToday {
      return .accentColor
    } else {
      return .primary
    }
  }
}

struct TodoIndicator: View {
  let count: Int

  var body: some View {
    Circle()
      .fill(Color.orange)
      .frame(width: 6, height: 6)
  }
}
