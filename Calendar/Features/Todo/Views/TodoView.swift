import SwiftData
import SwiftUI

// MARK: - Sort Order

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

// MARK: - Filter

enum TodoFilter: String, CaseIterable {
  case all, queued, completed

  var label: String {
    switch self {
    case .all: return Localization.string(.all)
    case .queued: return Localization.string(.queued)
    case .completed: return Localization.string(.completed)
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
  @State private var filter: TodoFilter = .all
  @State private var searchText: String = ""

  private var allTodos: [TodoItem] {
    allTodosRaw.filter { !$0.isSubtask }
  }

  private var filteredTodos: [TodoItem] {
    var result = allTodos
    if !searchText.isEmpty {
      result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    switch filter {
    case .all: break
    case .queued: result = result.filter { !$0.isCompleted }
    case .completed: result = result.filter { $0.isCompleted }
    }
    return result
  }

  // Summary counts
  private var totalCount: Int { allTodos.count }
  private var completedCount: Int { allTodos.filter(\.isCompleted).count }
  private var queuedCount: Int { allTodos.filter { !$0.isCompleted }.count }
  private var overdueCount: Int {
    allTodos.filter { !$0.isCompleted && ($0.dueDate ?? .distantFuture) < Date() }.count
  }

  private var pinnedCategories: [TodoCategory] {
    categories
      .filter { $0.parent == nil && $0.name != TodoViewModel.noCategoryName && $0.isPinned }
      .sorted { $0.sortOrder < $1.sortOrder }
  }

  private var unpinnedCategories: [TodoCategory] {
    categories
      .filter { $0.parent == nil && $0.name != TodoViewModel.noCategoryName && !$0.isPinned }
      .sorted { $0.sortOrder < $1.sortOrder }
  }

  private var unpinnedUncategorizedTodos: [TodoItem] {
    let todos = filteredTodos.filter {
      ($0.category == nil || $0.category?.name == TodoViewModel.noCategoryName) && !$0.isPinned
    }
    return sortTodos(todos)
  }

  private func todosForCategory(_ category: TodoCategory) -> [TodoItem] {
    let todos = filteredTodos.filter { $0.category?.id == category.id }
    return sortTodos(todos)
  }

  private func sortTodos(_ todos: [TodoItem]) -> [TodoItem] {
    let sorted: [TodoItem]
    switch sortOrder {
    case .manual: sorted = todos.sorted { $0.sortOrder < $1.sortOrder }
    case .newestFirst: sorted = todos.sorted { $0.createdAt > $1.createdAt }
    case .oldestFirst: sorted = todos.sorted { $0.createdAt < $1.createdAt }
    }
    return sorted.sorted { ($0.isPinned ? 0 : 1) < ($1.isPinned ? 0 : 1) }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header Section
      VStack(spacing: 16) {
          // Search Bar
          HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(.textSecondary)

            TextField(Localization.string(.search), text: $searchText)
              .font(Typography.body)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(.ultraThinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .glassHalo(cornerRadius: 16)
          
          // Analytics Cards
          HStack(spacing: 12) {
            SummaryCard(label: Localization.string(.all), count: totalCount, color: .accentColor)
            SummaryCard(label: Localization.string(.queued), count: queuedCount, color: .priorityMedium)
            SummaryCard(label: Localization.string(.completed), count: completedCount, color: .eventGreen)
          }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 20)

      ScrollView {
        VStack(spacing: 16) {
          // Status Filter
          HStack {
            Picker("", selection: $filter) {
              ForEach(TodoFilter.allCases, id: \.self) { f in
                Text(f.label).tag(f)
              }
            }
            .pickerStyle(.segmented)
            .background(.ultraThinMaterial.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            sortDropdown
          }
          .padding(.bottom, 8)

          // List Content
          if !pinnedCategories.isEmpty {
               SectionHeader(title: Localization.string(.pinned))
               ForEach(pinnedCategories) { category in
                 draggableCategoryCard(category: category)
               }

               // Divider between pinned and unpinned
               if !unpinnedCategories.isEmpty || !unpinnedUncategorizedTodos.isEmpty {
                 Divider()
                   .background(Color.white.opacity(0.15))
                   .padding(.vertical, 8)
               }
          }

          if !unpinnedUncategorizedTodos.isEmpty {
            SectionHeader(title: Localization.string(.noCategory))
            ForEach(unpinnedUncategorizedTodos) { todo in
              draggableTodoRow(todo: todo)
            }
          }

          ForEach(unpinnedCategories) { category in
            draggableCategoryCard(category: category)
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 120)
      }
    }
    .overlay(alignment: .bottomTrailing) {
        Menu {
          Button(action: { showingAddTodo = true }) {
            Label(Localization.string(.addTodo), systemImage: "checklist")
          }
          Button(action: { showingAddCategory = true }) {
            Label(Localization.string(.addCategory), systemImage: "folder.badge.plus")
          }
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(Color.accentColor)
            .clipShape(Circle())
            .shadow(color: Color.accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 100)
    }
    .sheet(isPresented: $showingAddTodo) {
      AddTodoSheet(categories: categories) {
        title, notes, priority, dueDate, reminder, category, recType, recInterval, recDays, recEnd,
        subtasks, repeatInterval, repeatCount in
        createTodo(title, notes, priority, dueDate, reminder, category, recType, recInterval, recDays, recEnd, subtasks, repeatInterval, repeatCount)
      }
    }
    .sheet(isPresented: $showingAddCategory) {
      AddCategorySheet(categories: categories, onSave: { name, color, parentCat in
        viewModel.createCategory(name: name, color: color, parent: parentCat, context: modelContext)
      })
    }
    .sheet(item: $editingCategory) { cat in
      AddCategorySheet(category: cat, categories: categories, onSave: { name, color, parentCat in
        viewModel.updateCategory(cat, name: name, color: color, parent: parentCat, context: modelContext)
      }, onDelete: {
        viewModel.deleteCategory(cat, context: modelContext)
      })
    }
    .sheet(item: $editingTodo) { todo in
      AddTodoSheet(todo: todo, categories: categories) {
        title, notes, priority, dueDate, reminder, category, recType, recInterval, recDays, recEnd,
        subtasks, repeatInterval, repeatCount in
        viewModel.updateTodo(todo, title: title, notes: notes, priority: priority, dueDate: dueDate, reminderInterval: reminder, reminderRepeatInterval: repeatInterval, reminderRepeatCount: repeatCount, category: category, recurrenceType: recType, recurrenceInterval: recInterval, recurrenceDaysOfWeek: recDays, recurrenceEndDate: recEnd, context: modelContext)
      } onDelete: {
        viewModel.deleteTodo(todo, context: modelContext)
      }
    }
  }

  private func createTodo(_ title: String, _ notes: String?, _ priority: Priority, _ dueDate: Date?, _ reminder: TimeInterval?, _ category: TodoCategory?, _ recType: RecurrenceType?, _ recInterval: Int, _ recDays: [Int]?, _ recEnd: Date?, _ subtasks: [String], _ repeatInterval: TimeInterval?, _ repeatCount: Int?) {
    viewModel.createTodo(title: title, notes: notes, priority: priority, dueDate: dueDate, reminderInterval: reminder, reminderRepeatInterval: repeatInterval, reminderRepeatCount: repeatCount, category: category, parentTodo: nil, recurrenceType: recType, recurrenceInterval: recInterval, recurrenceDaysOfWeek: recDays, recurrenceEndDate: recEnd, context: modelContext)
  }

  private var sortDropdown: some View {
    Menu {
      ForEach(TodoSortOrder.allCases, id: \.self) { order in
        Button(action: { sortOrder = order }) {
          HStack {
            Text(order.label)
            if sortOrder == order { Image(systemName: "checkmark") }
          }
        }
      }
    } label: {
      Image(systemName: "line.3.horizontal.decrease.circle")
        .font(.system(size: 18))
        .foregroundColor(.accentColor)
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
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
  }

  @ViewBuilder
  private func draggableCategoryCard(category: TodoCategory) -> some View {
    CategoryCard(
      category: category,
      todos: filteredTodos,
      isExpanded: { expandedCategories.contains($0.id) },
      onToggleExpand: { cat in
        withAnimation {
          if expandedCategories.contains(cat.id) { expandedCategories.remove(cat.id) }
          else { expandedCategories.insert(cat.id) }
        }
      },
      onEdit: { cat in editingCategory = cat },
      onDelete: { cat in viewModel.deleteCategory(cat, context: modelContext) },
      onTogglePin: { cat in viewModel.toggleCategoryPin(cat, context: modelContext) },
      onTodoToggle: { todo in viewModel.toggleCompletion(todo, context: modelContext) },
      onTodoTap: { todo in editingTodo = todo },
      onTodoDelete: { todo in viewModel.deleteTodo(todo, context: modelContext) },
      onTodoTogglePin: { todo in viewModel.toggleTodoPin(todo, context: modelContext) },
      onMoveTodo: { _, _ in },
      onDropItem: { _, _ in false },
      onTargetedChange: { _, _ in }
    )
    .onDrag {
      NSItemProvider(object: category.id.uuidString as NSString)
    }
    .dropDestination(for: String.self) { items, _ in
      guard let draggedId = items.first,
            let draggedUUID = UUID(uuidString: draggedId),
            let source = categories.first(where: { $0.id == draggedUUID }) else { return false }
      guard source.id != category.id else { return false }
      withAnimation {
        viewModel.reparentCategory(source, into: category, context: modelContext)
      }
      return true
    } isTargeted: { _ in
    }
  }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.textTertiary)
                .tracking(2)
            Spacer()
        }
        .padding(.leading, 4)
        .padding(.top, 8)
    }
}

private struct SummaryCard: View {
  let label: String
  let count: Int
  let color: Color
  var body: some View {
    VStack(spacing: 4) {
      Text("\(count)")
        .font(.system(size: 20, weight: .black, design: .rounded))
        .foregroundColor(color)
      Text(label.uppercased())
        .font(.system(size: 9, weight: .black))
        .foregroundColor(.textTertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .glassHalo(cornerRadius: 16)
  }
}
