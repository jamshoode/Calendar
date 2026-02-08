import SwiftUI

struct CategoryCard: View {
  let category: TodoCategory
  let todos: [TodoItem]
  let isExpanded: Bool
  let onToggleExpand: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void
  let onTogglePin: () -> Void
  let onTodoToggle: (TodoItem) -> Void
  let onTodoTap: (TodoItem) -> Void
  let onTodoDelete: (TodoItem) -> Void
  let onTodoTogglePin: (TodoItem) -> Void
  var onMoveTodo: ((TodoItem, Int) -> Void)? = nil

  private var incompleteTodos: [TodoItem] {
    todos.filter { !$0.isCompleted }
  }

  private var completedTodos: [TodoItem] {
    todos.filter { $0.isCompleted }
  }

  private var progress: Double {
    guard !todos.isEmpty else { return 0 }
    return Double(completedTodos.count) / Double(todos.count)
  }

  var body: some View {
    VStack(spacing: 0) {
      // Progress bar at top
      GeometryReader { geo in
        RoundedRectangle(cornerRadius: 2)
          .fill(Color.eventColor(named: category.color).opacity(0.3))
          .frame(height: 4)
          .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
              .fill(Color.eventColor(named: category.color))
              .frame(width: geo.size.width * progress, height: 4)
          }
      }
      .frame(height: 4)

      // Header
      Button(action: onToggleExpand) {
        HStack(spacing: 12) {
          Circle()
            .fill(Color.eventColor(named: category.color))
            .frame(width: 10, height: 10)

          if category.isPinned {
            Image(systemName: "pin.fill")
              .font(.system(size: 10))
              .foregroundColor(Color.textTertiary)
          }

          Text(category.name)
            .font(Typography.headline)
            .foregroundColor(Color.textPrimary)

          Spacer()

          Text("\(incompleteTodos.count)/\(todos.count)")
            .font(Typography.caption)
            .foregroundColor(Color.textSecondary)

          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color.textTertiary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, Spacing.md)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .contextMenu {
        Button(action: onTogglePin) {
          Label(
            category.isPinned ? Localization.string(.unpin) : Localization.string(.pin),
            systemImage: category.isPinned ? "pin.slash" : "pin"
          )
        }

        Button(action: onEdit) {
          Label(Localization.string(.edit), systemImage: "pencil")
        }

        Button(role: .destructive, action: onDelete) {
          Label(Localization.string(.delete), systemImage: "trash")
        }
      }

      if isExpanded {
        Divider()
          .padding(.horizontal, Spacing.md)

        VStack(spacing: 6) {
          ForEach(incompleteTodos, id: \.id) { todo in
            todoRowView(for: todo)
          }

          if !completedTodos.isEmpty {
            DisclosureGroup {
              ForEach(completedTodos, id: \.id) { todo in
                todoRowView(for: todo)
              }
            } label: {
              Text("\(completedTodos.count) \(Localization.string(.completed))")
                .font(Typography.caption)
                .foregroundColor(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
          }
        }
        .padding(.vertical, 8)
      }
    }
    .background(Color.surfaceCard)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
  }

  @ViewBuilder
  private func todoRowView(for todo: TodoItem) -> some View {
    TodoRow(
      todo: todo,
      onToggle: { onTodoToggle(todo) },
      onTap: { onTodoTap(todo) },
      onDelete: { onTodoDelete(todo) }
    )
    .draggable(todo.id.uuidString) {
      TodoRow(
        todo: todo,
        onToggle: {},
        onTap: {},
        onDelete: {}
      )
      .frame(width: 280)
      .opacity(0.8)
    }
    .contextMenu {
      Button(action: {
        onTodoTogglePin(todo)
      }) {
        Label(
          todo.isPinned ? Localization.string(.unpin) : Localization.string(.pin),
          systemImage: todo.isPinned ? "pin.slash" : "pin"
        )
      }

      Button(role: .destructive) {
        onTodoDelete(todo)
      } label: {
        Label(Localization.string(.delete), systemImage: "trash")
      }
    }
  }
}
