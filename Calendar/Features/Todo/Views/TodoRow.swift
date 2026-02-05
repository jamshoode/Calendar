import SwiftUI

struct TodoRow: View {
  let todo: TodoItem
  let onToggle: () -> Void
  let onTap: () -> Void
  let onDelete: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 12) {
        TodoCheckbox(
          isCompleted: todo.isCompleted,
          priority: todo.priorityEnum,
          action: onToggle
        )

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(todo.title)
              .font(.system(size: 16, weight: .medium))
              .strikethrough(todo.isCompleted)
              .foregroundColor(todo.isCompleted ? .secondary : .primary)

            if todo.isRecurring {
              Image(systemName: "repeat")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
          }

          HStack(spacing: 8) {
            if let dueDate = todo.dueDate {
              HStack(spacing: 4) {
                Image(systemName: "calendar")
                  .font(.system(size: 10))
                Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                  .font(.system(size: 12))
              }
              .foregroundColor(dueDateColor(dueDate))
            }

            if !todo.isCompleted {
              PriorityBadge(priority: todo.priorityEnum)
            }
          }
        }

        Spacer()
      }
      .contentShape(Rectangle())
      .onTapGesture(perform: onTap)

      if let subtasks = todo.subtasks, !subtasks.isEmpty {
        VStack(spacing: 0) {
          ForEach(subtasks) { subtask in
            SubtaskRow(
              subtask: subtask,
              onToggle: {},
              onDelete: {}
            )
          }
        }
        .padding(.top, 8)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .glassBackground(cornerRadius: 12)
    .swipeActions(edge: .trailing) {
      Button(role: .destructive, action: onDelete) {
        Label(Localization.string(.delete), systemImage: "trash")
      }
    }
  }

  private func dueDateColor(_ date: Date) -> Color {
    if todo.isCompleted { return .secondary }
    if date < Date() { return .red }
    if Calendar.current.isDateInToday(date) { return .orange }
    return .secondary
  }
}
