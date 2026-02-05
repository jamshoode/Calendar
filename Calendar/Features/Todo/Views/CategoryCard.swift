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

  var body: some View {
    VStack(spacing: 0) {
      Button(action: onToggleExpand) {
        HStack(spacing: 12) {
          Circle()
            .fill(Color.eventColor(named: category.color))
            .frame(width: 12, height: 12)

          if category.isPinned {
            Image(systemName: "pin.fill")
              .font(.system(size: 10))
              .foregroundColor(.secondary)
          }

          Text(category.name)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)

          Spacer()

          Text("\(incompleteTodos.count)")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)

          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
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
          .padding(.horizontal, 16)

        VStack(spacing: 8) {
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
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
          }
        }
        .padding(.vertical, 8)
      }
    }
    .glassBackground(cornerRadius: 16)
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
