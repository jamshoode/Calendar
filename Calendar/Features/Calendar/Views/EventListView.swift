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

  @State private var showingDetailSheet = false

  private var incompleteTodos: [TodoItem] {
    todos.filter { !$0.isCompleted }
  }

  private var isToday: Bool {
    guard let date else { return false }
    return Calendar.current.isDateInToday(date)
  }

  /// Combined items for preview (events first, then todos) — max 3
  private var allItemCount: Int {
    events.count + incompleteTodos.count
  }

  private var previewEvents: [Event] {
    Array(events.prefix(3))
  }

  private var previewTodos: [TodoItem] {
    let remaining = max(0, 3 - events.count)
    return Array(incompleteTodos.prefix(remaining))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Section header — tappable to expand
      headerView
        .contentShape(Rectangle())
        .onTapGesture {
          if allItemCount > 0 {
            showingDetailSheet = true
          }
        }

      // Fixed height content area for up to 3 events
      VStack(alignment: .leading, spacing: 4) {
        if events.isEmpty && incompleteTodos.isEmpty {
          emptyState
        } else {
          // Compact preview: max 3 items
          ForEach(previewEvents) { event in
            CompactEventRow(event: event)
              .onTapGesture { onEdit(event) }
          }
          .fixedSize(horizontal: false, vertical: true)

          ForEach(previewTodos) { todo in
            CompactTodoRow(todo: todo, onToggle: { onTodoToggle?(todo) })
              .onTapGesture { onTodoTap?(todo) }
          }
          .fixedSize(horizontal: false, vertical: true)

          if allItemCount > 3 {
            Button {
              showingDetailSheet = true
            } label: {
              Text("+\(allItemCount - 3) more")
                .font(Typography.caption)
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
            }
            .buttonStyle(.plain)
          }
        }
      }
      .frame(height: 140, alignment: .top)
      .padding(.horizontal, 16)
      .padding(.bottom, 12)
    }
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.surfaceCard)
    )
    .padding(.horizontal, 12)
    .padding(.top, 8)
    .padding(.bottom, 12)
    .sheet(isPresented: $showingDetailSheet) {
      EventListDetailSheet(
        date: date,
        events: events,
        todos: incompleteTodos,
        isToday: isToday,
        onEdit: onEdit,
        onDelete: onDelete,
        onAdd: onAdd,
        onTodoToggle: onTodoToggle,
        onTodoTap: onTodoTap
      )
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
    }
  }

  // MARK: - Header

  private var headerView: some View {
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
        // Jump to Today button in header
        if showJumpToToday, let onJumpToToday {
          Button(action: onJumpToToday) {
            HStack(spacing: 4) {
              Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 12, weight: .bold))
              Text("Today")
                .font(.system(size: 12, weight: .semibold))
            }
            .fixedSize()
            .foregroundColor(Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondaryFill)
            .clipShape(Capsule())
          }
          .buttonStyle(.plain)
          .transition(.scale.combined(with: .opacity))
        }
        
        if !events.isEmpty {
          Text(Localization.string(.eventsCount(events.count)))
            .font(Typography.caption)
            .foregroundColor(Color.textTertiary)
            .fixedSize()
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
  }

  // MARK: - Empty State

  private var emptyState: some View {
    Button(action: onAdd) {
      VStack(spacing: 6) {
        Image(systemName: "calendar.badge.plus")
          .font(.system(size: 28))
          .foregroundColor(Color.textTertiary)
        Text(Localization.string(.noEvents))
          .font(Typography.caption)
          .foregroundColor(Color.textSecondary)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }


}

// MARK: - Compact Event Row (smaller for preview)

struct CompactEventRow: View {
  let event: Event

  var body: some View {
    HStack(spacing: 8) {
      RoundedRectangle(cornerRadius: 2)
        .fill(Color.eventColor(named: event.color))
        .frame(width: 3)
        .padding(.vertical, 3)

      HStack(spacing: 8) {
        Text(event.title)
          .font(Typography.body)
          .foregroundColor(Color.textPrimary)
          .lineLimit(1)

        if event.isHoliday {
          Image(systemName: "star.fill")
            .font(.system(size: 9))
            .foregroundColor(.eventTeal)
        }

        Spacer()

        Text(event.date.formatted(date: .omitted, time: .shortened))
          .font(Typography.caption)
          .foregroundColor(Color.textSecondary)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
    }
    .background(event.isHoliday ? Color.eventTeal.opacity(0.06) : Color.backgroundSecondary)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - Compact Todo Row

struct CompactTodoRow: View {
  let todo: TodoItem
  let onToggle: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Button(action: onToggle) {
        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 16))
          .foregroundColor(priorityColor)
      }
      .buttonStyle(.plain)

      Text(todo.title)
        .font(Typography.body)
        .foregroundColor(Color.textPrimary)
        .lineLimit(1)

      Spacer()

      PriorityBadge(priority: todo.priorityEnum)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color.backgroundSecondary)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var priorityColor: Color {
    switch todo.priorityEnum {
    case .high: return .priorityHigh
    case .medium: return .priorityMedium
    case .low: return .priorityLow
    }
  }
}

// MARK: - Detail Sheet (full event list)

struct EventListDetailSheet: View {
  @Environment(\.dismiss) private var dismiss
  
  let date: Date?
  let events: [Event]
  let todos: [TodoItem]
  let isToday: Bool
  let onEdit: (Event) -> Void
  let onDelete: (Event) -> Void
  let onAdd: () -> Void
  var onTodoToggle: ((TodoItem) -> Void)?
  var onTodoTap: ((TodoItem) -> Void)?

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 6) {
          ForEach(events) { event in
            EventRow(event: event)
              .onTapGesture { onEdit(event) }
          }

          if !todos.isEmpty {
            HStack {
              Text(Localization.string(.tabTodo))
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.textTertiary)
              Spacer()
            }
            .padding(.top, 8)

            ForEach(todos) { todo in
              EventListTodoRow(
                todo: todo,
                onToggle: { onTodoToggle?(todo) },
                onTap: { onTodoTap?(todo) }
              )
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
      }
      .navigationTitle(isToday ? "Today" : (date?.formattedDate ?? ""))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              onAdd()
            }
          } label: {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 22))
              .foregroundColor(.accentColor)
          }
        }
      }
    }
  }
}

// MARK: - Full-size Event Row (for detail sheet)

struct EventRow: View {
  let event: Event

  var body: some View {
    HStack(spacing: 0) {
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

// MARK: - Full-size Todo Row (for detail sheet)

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
