import SwiftUI
import SwiftData

struct CategoryCard: View {
  let category: TodoCategory
  let todos: [TodoItem]
  let isExpanded: Bool
  let onToggleExpand: () -> Void
  let onEdit: (TodoCategory) -> Void
  let onDelete: (TodoCategory) -> Void
  let onTogglePin: (TodoCategory) -> Void
  let onTodoToggle: (TodoItem) -> Void
  let onTodoTap: (TodoItem) -> Void
  let onTodoDelete: (TodoItem) -> Void
  let onTodoTogglePin: (TodoItem) -> Void
  var onMoveTodo: ((TodoItem, Int) -> Void)? = nil
  var onDropItem: ((String, TodoCategory) -> Bool)? = nil
  var onTargetedChange: ((Bool, TodoCategory) -> Void)? = nil
  var onTodoTapInCategory: ((TodoItem) -> Void)? = nil

  @Environment(\.modelContext) private var modelContext
  @State private var expandedSubcategories: Set<UUID> = []
  
  private var incompleteTodos: [TodoItem] {
    todos.filter { !$0.isCompleted }
  }

  private var completedTodos: [TodoItem] {
    todos.filter { $0.isCompleted }
  }

  private var allTodosInHierarchy: [TodoItem] {
    var result = todos
    if let subcats = category.subcategories {
      for subcat in subcats {
        result.append(contentsOf: getTodosRecursive(category: subcat))
      }
    }
    return result
  }

  private func getTodosRecursive(category: TodoCategory) -> [TodoItem] {
    var result = category.todos ?? []
    if let subcats = category.subcategories {
      for subcat in subcats {
        result.append(contentsOf: getTodosRecursive(category: subcat))
      }
    }
    return result
  }

  private var progress: Double {
    let all = allTodosInHierarchy
    guard !all.isEmpty else { return 0 }
    let completedCount = all.filter { $0.isCompleted }.count
    return Double(completedCount) / Double(all.count)
  }

  var body: some View {
    VStack(spacing: 0) {
      if category.depth == 0 {
        // Progress bar at top only for root categories
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
      }

      // Header
      Button(action: onToggleExpand) {
        HStack(spacing: 12) {
          Circle()
            .fill(Color.eventColor(named: category.color))
            .frame(width: category.depth == 0 ? 10 : 8, height: category.depth == 0 ? 10 : 8)

          if category.isPinned {
            Image(systemName: "pin.fill")
              .font(.system(size: category.depth == 0 ? 10 : 8))
              .foregroundColor(Color.textTertiary)
          }

          Text(category.name)
            .font(category.depth == 0 ? Typography.headline : Typography.body)
            .foregroundColor(Color.textPrimary)

          Spacer()

          Text("\(incompleteTodos.count)/\(todos.count)")
            .font(Typography.caption)
            .foregroundColor(Color.textSecondary)

          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color.textTertiary)
        }
        .padding(.vertical, category.depth == 0 ? 14 : 10)
        .padding(.horizontal, category.depth == 0 ? Spacing.md : 4)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .contextMenu {
        Button(action: { onTogglePin(category) }) {
          Label(
            category.isPinned ? Localization.string(.unpin) : Localization.string(.pin),
            systemImage: category.isPinned ? "pin.slash" : "pin"
          )
        }

        Button(action: { onEdit(category) }) {
          Label(Localization.string(.edit), systemImage: "pencil")
        }

        Button(role: .destructive, action: { onDelete(category) }) {
          Label(Localization.string(.delete), systemImage: "trash")
        }
      }

      if isExpanded {
        if category.depth == 0 {
          Divider()
            .padding(.horizontal, Spacing.md)
        }

        VStack(spacing: 6) {
          ForEach(incompleteTodos, id: \.id) { todo in
            todoRowView(for: todo)
          }

          if let subcats = category.subcategories, !subcats.isEmpty {
            VStack(spacing: 8) {
              ForEach(subcats.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { subcat in
                CategoryCard(
                  category: subcat,
                  todos: subcat.todos ?? [],
                  isExpanded: expandedSubcategories.contains(subcat.id),
                  onToggleExpand: {
                    withAnimation {
                      if expandedSubcategories.contains(subcat.id) {
                        expandedSubcategories.remove(subcat.id)
                      } else {
                        expandedSubcategories.insert(subcat.id)
                      }
                    }
                  },
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onTogglePin: onTogglePin,
                  onTodoToggle: onTodoToggle,
                  onTodoTap: onTodoTap,
                  onTodoDelete: onTodoDelete,
                  onTodoTogglePin: onTodoTogglePin,
                  onMoveTodo: onMoveTodo,
                  onDropItem: onDropItem,
                  onTargetedChange: onTargetedChange
                )
              }
            }
            .padding(.leading, 16)
            .padding(.top, 4)
            .overlay(alignment: .leading) {
              // Vertical guide line
              Rectangle()
                .fill(Color.eventColor(named: category.color).opacity(0.3))
                .frame(width: 2)
                .padding(.leading, 4)
                .padding(.vertical, 4)
            }
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
            .padding(.horizontal, category.depth == 0 ? Spacing.md : 4)
            .padding(.vertical, 4)
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, category.depth == 0 ? 0 : 4)
      }
    }
    .background(category.depth == 0 ? Color.surfaceCard : Color.clear)
    .clipShape(RoundedRectangle(cornerRadius: category.depth == 0 ? Spacing.cardRadius : 0))
    .padding(.bottom, category.depth == 0 ? 8 : 0)
    .draggable(category.id.uuidString) {
      Text(category.name)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
    }
    .dropDestination(for: String.self) { items, _ in
      guard let idString = items.first else { return false }
      return onDropItem?(idString, category) ?? false
    } isTargeted: { isTargeted in
      onTargetedChange?(isTargeted, category)
    }
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
