import SwiftUI

struct EventListView: View {
  let date: Date?
  let events: [Event]
  var todos: [TodoItem] = []
  let onEdit: (Event) -> Void
  let onDelete: (Event) -> Void
  let onAdd: () -> Void
  var onTodoToggle: ((TodoItem) -> Void)?
  var onTodoTap: ((TodoItem) -> Void)?
  var showJumpToToday: Bool = false
  var onJumpToToday: (() -> Void)?

  private var incompleteTodos: [TodoItem] {
    todos.filter { !$0.isCompleted }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        if let date = date {
          Text(date.formattedDate)
            .font(.system(size: 18, weight: .semibold))
        } else {
          Text(Localization.string(.selectDate))
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.secondary)
        }

        Spacer()

        Button(action: onAdd) {
          Image(systemName: "plus.circle.fill")
            .font(.system(size: 24))
            .foregroundColor(.accentColor)
        }
        .accessibilityLabel(Localization.string(.addEvent))
      }

      if events.isEmpty && incompleteTodos.isEmpty {
        Spacer()
        Button(action: onAdd) {
          VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
              .font(.system(size: 40))
              .foregroundColor(.secondary)
            Text(Localization.string(.noEvents))
              .foregroundColor(.secondary)
            Text(Localization.string(.tapToAdd))
              .font(.caption)
              .foregroundColor(.secondary.opacity(0.8))
          }
          .frame(maxWidth: .infinity, minHeight: 100)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        Spacer()
      } else {
        HStack {
          Spacer()
          Text(Localization.string(.eventsCount(events.count)))
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .padding(.bottom, -8)

        ScrollView {
          LazyVStack(spacing: 8) {
            ForEach(events) { event in
              EventRow(event: event)
                .onTapGesture {
                  onEdit(event)
                }
                .if(!event.isHoliday) { view in
                  view.swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                      onDelete(event)
                    } label: {
                      Label(Localization.string(.delete), systemImage: "trash")
                    }
                  }
                }
            }

            if !incompleteTodos.isEmpty {
              HStack {
                Text(Localization.string(.tabTodo))
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(.secondary)
                Spacer()
              }
              .padding(.top, 8)

              ForEach(incompleteTodos) { todo in
                EventListTodoRow(
                  todo: todo,
                  onToggle: { onTodoToggle?(todo) },
                  onTap: { onTodoTap?(todo) }
                )
              }
            }
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .frame(maxHeight: .infinity, alignment: .top)
    .overlay(alignment: .bottomTrailing) {
      if showJumpToToday, let onJumpToToday = onJumpToToday {
        Button(action: onJumpToToday) {
          HStack(spacing: 6) {
            Image(systemName: "arrow.counterclockwise")
              .font(.system(size: 13, weight: .bold))
            Text("Today")
              .font(.system(size: 13, weight: .semibold))
          }
          .foregroundColor(.primary)
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .background(Color.secondaryFill)
          .clipShape(Capsule())
          .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 8)
        .padding(.bottom, 8)
        .transition(.scale.combined(with: .opacity))
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.surfaceCard)
    )
    .padding(.horizontal, 12)
    .padding(.top, 8)
  }
}

struct EventListTodoRow: View {
  let todo: TodoItem
  let onToggle: () -> Void
  let onTap: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onToggle) {
        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 20))
          .foregroundColor(priorityColor)
      }
      .buttonStyle(.plain)

      VStack(alignment: .leading, spacing: 4) {
        Text(todo.title)
          .font(.system(size: 16, weight: .medium))
          .strikethrough(todo.isCompleted)
          .foregroundColor(todo.isCompleted ? .secondary : .primary)

        if let dueDate = todo.dueDate {
          Text(dueDate.formatted(date: .omitted, time: .shortened))
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      PriorityBadge(priority: todo.priorityEnum)
    }
    .padding()
    .background(Color.orange.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .onTapGesture(perform: onTap)
  }

  private var priorityColor: Color {
    switch todo.priorityEnum {
    case .high: return .red
    case .medium: return .orange
    case .low: return .blue
    }
  }
}

struct EventRow: View {
  let event: Event

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Color.eventColor(named: event.color))
        .frame(width: 12, height: 12)

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(event.title)
            .font(.system(size: 16, weight: .medium))

          if event.isHoliday {
            Image(systemName: "star.fill")
              .font(.system(size: 10))
              .foregroundColor(.eventTeal)
          }
        }

        if let notes = event.notes, !notes.isEmpty {
          Text(notes)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }

      Spacer()
    }
    .padding()
    .background(event.isHoliday ? Color.eventTeal.opacity(0.08) : Color.surfaceCard)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}
