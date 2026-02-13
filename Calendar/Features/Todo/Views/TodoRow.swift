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
              .font(Typography.body)
              .fontWeight(.medium)
              .strikethrough(todo.isCompleted)
              .foregroundColor(todo.isCompleted ? Color.textTertiary : Color.textPrimary)

            if todo.isRecurring {
              Image(systemName: "repeat")
                .font(.system(size: 12))
                .foregroundColor(Color.textTertiary)
            }
          }

          HStack(spacing: 8) {
            if let dueDate = todo.dueDate {
              HStack(spacing: 4) {
                Image(systemName: "calendar")
                  .font(.system(size: 10))
                Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                  .font(Typography.caption)
              }
              .foregroundColor(dueDateColor(dueDate))
            }

            if !todo.isCompleted {
              PriorityBadge(priority: todo.priorityEnum)
            }
          }
        }

        Spacer()

        if todo.isPinned {
          Image(systemName: "pin.fill")
            .font(.system(size: 10))
            .foregroundColor(Color.textTertiary)
        }
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
    .padding(.horizontal, 14)
    .background(.ultraThinMaterial.opacity(0.5))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .glassHalo(cornerRadius: 12)
    .swipeActions(edge: .trailing) {
      Button(role: .destructive, action: onDelete) {
        Label(Localization.string(.delete), systemImage: "trash")
      }
    }
  }

  private func dueDateColor(_ date: Date) -> Color {
    if todo.isCompleted { return Color.textTertiary }
    if date < Date() { return .priorityHigh }
    if Calendar.current.isDateInToday(date) { return .priorityMedium }
    return Color.textSecondary
  }
}
