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

  private var isToday: Bool {
    guard let date else { return false }
    return Calendar.current.isDateInToday(date)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Section header
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          if isToday {
            Text("Today")
              .font(Typography.headline)
              .foregroundColor(.accentColor)
          }
          if let date {
            Text(date.formattedDate)
              .font(isToday ? Typography.caption : Typography.headline)
              .foregroundColor(isToday ? Color.textSecondary : Color.textPrimary)
          }
        }

        Spacer()

        HStack(spacing: 8) {
          if !events.isEmpty {
            Text(Localization.string(.eventsCount(events.count)))
              .font(Typography.caption)
              .foregroundColor(Color.textTertiary)
          }

          Button(action: onAdd) {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 22))
              .foregroundColor(.accentColor)
          }
          .accessibilityLabel(Localization.string(.addEvent))
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 14)
      .padding(.bottom, 10)

      if events.isEmpty && incompleteTodos.isEmpty {
        Spacer()
        emptyState
        Spacer()
      } else {
        ScrollView {
          LazyVStack(spacing: 6) {
            ForEach(events) { event in
              EventRow(event: event)
                .onTapGesture { onEdit(event) }
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
              todoSection
            }
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 14)
        }
      }
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .overlay(alignment: .bottomTrailing) {
      jumpToTodayButton
    }
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.surfaceCard)
    )
    .padding(.horizontal, 12)
    .padding(.top, 8)
  }

  // MARK: - Empty State

  private var emptyState: some View {
    Button(action: onAdd) {
      VStack(spacing: 8) {
        Image(systemName: "calendar.badge.plus")
          .font(.system(size: 36))
          .foregroundColor(Color.textTertiary)
        Text(Localization.string(.noEvents))
          .font(Typography.body)
          .foregroundColor(Color.textSecondary)
        Text(Localization.string(.tapToAdd))
          .font(Typography.caption)
          .foregroundColor(Color.textTertiary)
      }
      .frame(maxWidth: .infinity, minHeight: 100)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  // MARK: - Todo Section

  private var todoSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(Localization.string(.tabTodo))
          .font(Typography.caption)
          .fontWeight(.semibold)
          .foregroundColor(Color.textTertiary)
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

  // MARK: - Jump to Today

  @ViewBuilder
  private var jumpToTodayButton: some View {
    if showJumpToToday, let onJumpToToday {
      Button(action: onJumpToToday) {
        HStack(spacing: 6) {
          Image(systemName: "arrow.counterclockwise")
            .font(.system(size: 13, weight: .bold))
          Text("Today")
            .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(Color.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.secondaryFill)
        .clipShape(Capsule())
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 4)
      }
      .padding(.trailing, 12)
      .padding(.bottom, 12)
      .transition(.scale.combined(with: .opacity))
    }
  }
}

// MARK: - Event Row (with left color bar)

struct EventRow: View {
  let event: Event

  var body: some View {
    HStack(spacing: 0) {
      // Color bar
      RoundedRectangle(cornerRadius: 2)
        .fill(Color.eventColor(named: event.color))
        .frame(width: 4)
        .padding(.vertical, 4)

      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(event.title)
              .font(Typography.body)
              .fontWeight(.medium)
              .foregroundColor(Color.textPrimary)

            if event.isHoliday {
              Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.eventTeal)
            }
          }

          HStack(spacing: 8) {
            Text(event.date.formatted(date: .omitted, time: .shortened))
              .font(Typography.caption)
              .foregroundColor(Color.textSecondary)

            if let notes = event.notes, !notes.isEmpty {
              Text(notes)
                .font(Typography.caption)
                .foregroundColor(Color.textTertiary)
                .lineLimit(1)
            }
          }
        }

        Spacer()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
    }
    .background(event.isHoliday ? Color.eventTeal.opacity(0.06) : Color.backgroundSecondary)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
  }
}

// MARK: - Todo Row

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
          .font(Typography.body)
          .fontWeight(.medium)
          .strikethrough(todo.isCompleted)
          .foregroundColor(todo.isCompleted ? Color.textTertiary : Color.textPrimary)

        if let dueDate = todo.dueDate {
          Text(dueDate.formatted(date: .omitted, time: .shortened))
            .font(Typography.caption)
            .foregroundColor(Color.textSecondary)
        }
      }

      Spacer()

      PriorityBadge(priority: todo.priorityEnum)
    }
    .padding(12)
    .background(Color.backgroundSecondary)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
    .onTapGesture(perform: onTap)
  }

  private var priorityColor: Color {
    switch todo.priorityEnum {
    case .high: return .priorityHigh
    case .medium: return .priorityMedium
    case .low: return .priorityLow
    }
  }
}
