import SwiftData
import SwiftUI

enum TodoSortOrder: String, CaseIterable {
  case manual
  case newestFirst
  case oldestFirst

  var label: String {
    switch self {
    case .manual: return Localization.string(.manual)
    case .newestFirst: return Localization.string(.newestFirst)
    case .oldestFirst: return Localization.string(.oldestFirst)
    }
  }
}

struct TodoView: View {
  @StateObject private var viewModel = TodoViewModel()
  @Query(sort: \TodoCategory.createdAt) private var categories: [TodoCategory]
  @Query(sort: \TodoItem.createdAt) private var allTodosRaw: [TodoItem]
  @Environment(\.modelContext) private var modelContext

  @State private var expandedCategories: Set<UUID> = []
  @State private var showingAddTodo = false
  @State private var showingAddCategory = false
  @State private var editingTodo: TodoItem?
  @State private var editingCategory: TodoCategory?
  @State private var sortOrder: TodoSortOrder = .manual
  @State private var draggedTodo: TodoItem?
  @State private var draggedCategory: TodoCategory?
  @State private var dropTargetCategory: TodoCategory?

  private var allTodos: [TodoItem] {
    allTodosRaw.filter { !$0.isSubtask }
  }

  private var isListEmpty: Bool {
    allTodos.isEmpty && categories.filter({ $0.name != TodoViewModel.noCategoryName }).isEmpty
  }

  private var pinnedCategories: [TodoCategory] {
    categories
      .filter { $0.name != TodoViewModel.noCategoryName && $0.isPinned }
      .sorted { $0.sortOrder < $1.sortOrder }
  }

  private var unpinnedCategories: [TodoCategory] {
    categories
      .filter { $0.name != TodoViewModel.noCategoryName && !$0.isPinned }
      .sorted { $0.sortOrder < $1.sortOrder }
  }

  private var pinnedUncategorizedTodos: [TodoItem] {
    let todos = allTodos.filter {
      ($0.category == nil || $0.category?.name == TodoViewModel.noCategoryName) && $0.isPinned
    }
    return sortTodos(todos)
  }

  private var unpinnedUncategorizedTodos: [TodoItem] {
    let todos = allTodos.filter {
      ($0.category == nil || $0.category?.name == TodoViewModel.noCategoryName) && !$0.isPinned
    }
    return sortTodos(todos)
  }

  private func todosForCategory(_ category: TodoCategory) -> [TodoItem] {
    let todos = allTodos.filter { $0.category?.id == category.id }
    return sortTodos(todos)
  }

  private func sortTodos(_ todos: [TodoItem]) -> [TodoItem] {
    let sorted: [TodoItem]
    switch sortOrder {
    case .manual:
      sorted = todos.sorted { $0.sortOrder < $1.sortOrder }
    case .newestFirst:
      sorted = todos.sorted { $0.createdAt > $1.createdAt }
    case .oldestFirst:
      sorted = todos.sorted { $0.createdAt < $1.createdAt }
    }
    return sorted.sorted { ($0.isPinned ? 0 : 1) < ($1.isPinned ? 0 : 1) }
  }

  var body: some View {
    ZStack {
      if isListEmpty {
        EmptyTodoView(
          onAddTodo: { showingAddTodo = true },
          onAddCategory: { showingAddCategory = true }
        )
      } else {
        ScrollView {
          LazyVStack(spacing: 12) {
            sortDropdown
              .padding(.bottom, 8)

            if !pinnedCategories.isEmpty || !pinnedUncategorizedTodos.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                Text(Localization.string(.pinned))
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(.secondary)
                  .padding(.horizontal, 16)

                ForEach(pinnedCategories, id: \.id) { category in
                  draggableCategoryCard(category: category)
                }

                ForEach(pinnedUncategorizedTodos, id: \.id) { todo in
                  draggableTodoRow(todo: todo)
                }
              }
            }

            if (!pinnedCategories.isEmpty || !pinnedUncategorizedTodos.isEmpty)
              && (!unpinnedCategories.isEmpty || !unpinnedUncategorizedTodos.isEmpty)
            {
              Rectangle()
                .fill(Color.separator)
                .frame(height: 1)
                .padding(.vertical, 8)
            }

            if !unpinnedUncategorizedTodos.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                Text(Localization.string(.noCategory))
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(.secondary)
                  .padding(.horizontal, 16)

                ForEach(unpinnedUncategorizedTodos, id: \.id) { todo in
                  draggableTodoRow(todo: todo)
                }
              }
            }

            ForEach(unpinnedCategories, id: \.id) { category in
              draggableCategoryCard(category: category)
            }
          }
          .padding(.horizontal)
          .padding(.top, 12)
          .padding(.bottom, 100)
        }

        VStack {
          Spacer()
          HStack {
            Spacer()

            Menu {
              Button(action: { showingAddTodo = true }) {
                Label(Localization.string(.addTodo), systemImage: "checkmark.circle")
              }
              Button(action: { showingAddCategory = true }) {
                Label(Localization.string(.addCategory), systemImage: "folder.badge.plus")
              }
            } label: {
              Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
          }
        }
      }
    }
    .onAppear {
      viewModel.createDefaultCategoryIfNeeded(context: modelContext)
      viewModel.cleanupCompletedTodos(context: modelContext)
    }
    .sheet(isPresented: $showingAddTodo) {
      AddTodoSheet(categories: categories) {
        title, notes, priority, dueDate, reminder, category, recType, recInterval, recDays, recEnd,
        subtasks, repeatInterval, repeatCount in
        createTodo(
          title: title, notes: notes, priority: priority, dueDate: dueDate, reminder: reminder,
          category: category, recType: recType, recInterval: recInterval, recDays: recDays,
          recEnd: recEnd, subtasks: subtasks, repeatInterval: repeatInterval,
          repeatCount: repeatCount)
      }
    }
    .sheet(isPresented: $showingAddCategory) {
      AddCategorySheet { name, color in
        viewModel.createCategory(name: name, color: color, context: modelContext)
      }
    }
    .sheet(item: $editingTodo) { todo in
      AddTodoSheet(
        todo: todo,
        categories: categories,
        onSave: {
          title, notes, priority, dueDate, reminder, category, recType, recInterval, recDays,
          recEnd, subtasks, repeatInterval, repeatCount in
          updateTodo(
            todo, title: title, notes: notes, priority: priority, dueDate: dueDate,
            reminder: reminder, category: category, recType: recType, recInterval: recInterval,
            recDays: recDays, recEnd: recEnd, subtasks: subtasks, repeatInterval: repeatInterval,
            repeatCount: repeatCount)
        },
        onDelete: {
          viewModel.deleteTodo(todo, context: modelContext)
        }
      )
    }
    .sheet(item: $editingCategory) { category in
      AddCategorySheet(
        category: category,
        onSave: { name, color in
          viewModel.updateCategory(category, name: name, color: color, context: modelContext)
        },
        onDelete: {
          viewModel.deleteCategory(category, context: modelContext)
        }
      )
    }
  }

  private func createTodo(
    title: String, notes: String?, priority: Priority, dueDate: Date?, reminder: TimeInterval?,
    category: TodoCategory?, recType: RecurrenceType?, recInterval: Int, recDays: [Int]?,
    recEnd: Date?, subtasks: [String], repeatInterval: TimeInterval?, repeatCount: Int?
  ) {
    viewModel.createTodo(
      title: title,
      notes: notes,
      priority: priority,
      dueDate: dueDate,
      reminderInterval: reminder,
      reminderRepeatInterval: repeatInterval,
      reminderRepeatCount: repeatCount,
      category: category,
      parentTodo: nil,
      recurrenceType: recType,
      recurrenceInterval: recInterval,
      recurrenceDaysOfWeek: recDays,
      recurrenceEndDate: recEnd,
      context: modelContext
    )

    if !subtasks.isEmpty {
      let descriptor = FetchDescriptor<TodoItem>(
        predicate: #Predicate { $0.title == title },
        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
      )
      if let newTodo = try? modelContext.fetch(descriptor).first {
        for subtaskTitle in subtasks {
          viewModel.addSubtask(to: newTodo, title: subtaskTitle, context: modelContext)
        }
      }
    }
  }

  private func updateTodo(
    _ todo: TodoItem, title: String, notes: String?, priority: Priority, dueDate: Date?,
    reminder: TimeInterval?, category: TodoCategory?, recType: RecurrenceType?, recInterval: Int,
    recDays: [Int]?, recEnd: Date?, subtasks: [String], repeatInterval: TimeInterval?,
    repeatCount: Int?
  ) {
    viewModel.updateTodo(
      todo,
      title: title,
      notes: notes,
      priority: priority,
      dueDate: dueDate,
      reminderInterval: reminder,
      reminderRepeatInterval: repeatInterval,
      reminderRepeatCount: repeatCount,
      category: category,
      recurrenceType: recType,
      recurrenceInterval: recInterval,
      recurrenceDaysOfWeek: recDays,
      recurrenceEndDate: recEnd,
      context: modelContext
    )

    if let existingSubtasks = todo.subtasks {
      for subtask in existingSubtasks {
        modelContext.delete(subtask)
      }
    }

    for subtaskTitle in subtasks {
      viewModel.addSubtask(to: todo, title: subtaskTitle, context: modelContext)
    }
  }

  private var sortDropdown: some View {
    HStack {
      Menu {
        ForEach(TodoSortOrder.allCases, id: \.self) { order in
          Button(action: { sortOrder = order }) {
            HStack {
              Text(order.label)
              if sortOrder == order {
                Image(systemName: "checkmark")
              }
            }
          }
        }
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "arrow.up.arrow.down")
            .font(.system(size: 14, weight: .medium))
          Text(sortOrder.label)
            .font(.system(size: 14, weight: .medium))
            .frame(minWidth: 80, alignment: .center)
          Image(systemName: "chevron.down")
            .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassBackground(cornerRadius: 10)
      }
      Spacer()
    }
  }

  @ViewBuilder
  private func draggableTodoRow(todo: TodoItem) -> some View {
    TodoRow(
      todo: todo,
      onToggle: { viewModel.toggleCompletion(todo, context: modelContext) },
      onTap: { editingTodo = todo },
      onDelete: { viewModel.deleteTodo(todo, context: modelContext) }
    )
    .draggable(todo.id.uuidString) {
      TodoRow(
        todo: todo,
        onToggle: {},
        onTap: {},
        onDelete: {}
      )
      .frame(width: 300)
      .opacity(0.8)
    }
    .contextMenu {
      Button(action: {
        viewModel.toggleTodoPin(todo, context: modelContext)
      }) {
        Label(
          todo.isPinned ? Localization.string(.unpin) : Localization.string(.pin),
          systemImage: todo.isPinned ? "pin.slash" : "pin"
        )
      }

      Button(role: .destructive) {
        viewModel.deleteTodo(todo, context: modelContext)
      } label: {
        Label(Localization.string(.delete), systemImage: "trash")
      }
    }
  }

  @ViewBuilder
  private func draggableCategoryCard(category: TodoCategory) -> some View {
    CategoryCard(
      category: category,
      todos: todosForCategory(category),
      isExpanded: expandedCategories.contains(category.id),
      onToggleExpand: {
        withAnimation(.easeInOut(duration: 0.2)) {
          if expandedCategories.contains(category.id) {
            expandedCategories.remove(category.id)
          } else {
            expandedCategories.insert(category.id)
          }
        }
      },
      onEdit: { editingCategory = category },
      onDelete: { viewModel.deleteCategory(category, context: modelContext) },
      onTogglePin: { viewModel.toggleCategoryPin(category, context: modelContext) },
      onTodoToggle: { todo in viewModel.toggleCompletion(todo, context: modelContext) },
      onTodoTap: { todo in editingTodo = todo },
      onTodoDelete: { todo in viewModel.deleteTodo(todo, context: modelContext) },
      onTodoTogglePin: { todo in viewModel.toggleTodoPin(todo, context: modelContext) },
      onMoveTodo: { todo, newIndex in
        moveTodo(todo, toIndex: newIndex, inCategory: category)
      }
    )
    .draggable(category.id.uuidString) {
      Text(category.name)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassBackground()
    }
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.accentColor, lineWidth: dropTargetCategory?.id == category.id ? 2 : 0)
    )
    .dropDestination(for: String.self) { items, _ in
      guard let idString = items.first else { return false }

      if let todoId = UUID(uuidString: idString),
        let todo = allTodos.first(where: { $0.id == todoId })
      {
        todo.category = category
        try? modelContext.save()
        return true
      }

      if let droppedCategoryId = UUID(uuidString: idString),
        let draggedCat = categories.first(where: { $0.id == droppedCategoryId }),
        draggedCat.id != category.id
      {
        let targetList = category.isPinned ? pinnedCategories : unpinnedCategories
        if let targetIndex = targetList.firstIndex(where: { $0.id == category.id }) {
          moveCategory(draggedCat, toIndex: targetIndex, inPinnedList: category.isPinned)
        }
        return true
      }

      return false
    } isTargeted: { isTargeted in
      withAnimation(.easeInOut(duration: 0.15)) {
        dropTargetCategory = isTargeted ? category : nil
      }
    }
  }

  private func moveCategory(_ category: TodoCategory, toIndex newIndex: Int, inPinnedList: Bool) {
    let categoryList = inPinnedList ? pinnedCategories : unpinnedCategories

    if category.isPinned != inPinnedList {
      category.isPinned = inPinnedList
    }

    for (index, c) in categoryList.enumerated() {
      c.sortOrder = index < newIndex ? index : index + 1
    }
    category.sortOrder = newIndex

    try? modelContext.save()
  }

  private func moveTodo(_ todo: TodoItem, toIndex newIndex: Int, inCategory category: TodoCategory?)
  {
    let allUncategorized = pinnedUncategorizedTodos + unpinnedUncategorizedTodos
    let todos = category == nil ? allUncategorized : todosForCategory(category!)

    for (index, t) in todos.enumerated() {
      t.sortOrder = index < newIndex ? index : index + 1
    }
    todo.sortOrder = newIndex

    try? modelContext.save()
  }
}

struct EmptyTodoView: View {
  let onAddTodo: () -> Void
  let onAddCategory: () -> Void

  var body: some View {
    VStack(spacing: 32) {
      ZStack {
        Circle()
          .fill(Color.accentColor.opacity(0.1))
          .frame(width: 140, height: 140)
          .overlay(
            Circle()
              .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
          )

        Image(systemName: "checkmark.circle")
          .font(.system(size: 64))
          .foregroundColor(.accentColor)
          .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
      }
      .padding(.bottom, 10)
      .accessibilityHidden(true)

      VStack(spacing: 12) {
        Text(Localization.string(.noTodos))
          .font(.title2.weight(.bold))
          .foregroundColor(.primary)

        Text(Localization.string(.tapToAddTodo))
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }

      Menu {
        Button(action: onAddTodo) {
          Label(Localization.string(.addTodo), systemImage: "checkmark.circle")
        }
        Button(action: onAddCategory) {
          Label(Localization.string(.addCategory), systemImage: "folder.badge.plus")
        }
      } label: {
        HStack {
          Image(systemName: "plus")
            .font(.headline)
          Text(Localization.string(.addTodo))
            .font(.headline)
        }
        .foregroundColor(.white)
        .frame(height: 50)
        .padding(.horizontal, 32)
        .background(
          Capsule()
            .fill(Color.accentColor)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
        )
      }
      .padding(.top, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
