import Combine
import SwiftData
import SwiftUI

class TodoViewModel: ObservableObject {

  static let noCategoryName = "No Category"

  func createCategory(name: String, color: String, context: ModelContext) {
    let descriptor = FetchDescriptor<TodoCategory>()
    let existingCount = (try? context.fetchCount(descriptor)) ?? 0
    let category = TodoCategory(name: name, color: color, sortOrder: existingCount)
    context.insert(category)
    try? context.save()
  }

  func updateCategory(_ category: TodoCategory, name: String, color: String, context: ModelContext)
  {
    category.name = name
    category.color = color
    try? context.save()
  }

  func deleteCategory(_ category: TodoCategory, context: ModelContext) {
    context.delete(category)
    try? context.save()
  }

  func toggleCategoryPin(_ category: TodoCategory, context: ModelContext) {
    category.isPinned.toggle()
    try? context.save()
  }

  func toggleTodoPin(_ todo: TodoItem, context: ModelContext) {
    todo.isPinned.toggle()
    try? context.save()
  }

  func createTodo(
    title: String,
    notes: String?,
    priority: Priority,
    dueDate: Date?,
    reminderInterval: TimeInterval?,
    category: TodoCategory?,
    parentTodo: TodoItem?,
    recurrenceType: RecurrenceType?,
    recurrenceInterval: Int,
    recurrenceDaysOfWeek: [Int]?,
    recurrenceEndDate: Date?,
    context: ModelContext
  ) {
    let todo = TodoItem(
      title: title,
      notes: notes,
      priority: priority,
      dueDate: dueDate,
      reminderInterval: reminderInterval,
      parentTodo: parentTodo,
      recurrenceType: recurrenceType,
      recurrenceInterval: recurrenceInterval,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek,
      recurrenceEndDate: recurrenceEndDate
    )
    context.insert(todo)

    if let category = category {
      todo.category = category
      category.todos?.append(todo)
    }

    try? context.save()

    if dueDate != nil && reminderInterval != nil {
      NotificationService.shared.scheduleTodoNotification(todo: todo)
    }
  }

  func updateTodo(
    _ todo: TodoItem,
    title: String,
    notes: String?,
    priority: Priority,
    dueDate: Date?,
    reminderInterval: TimeInterval?,
    category: TodoCategory?,
    recurrenceType: RecurrenceType?,
    recurrenceInterval: Int,
    recurrenceDaysOfWeek: [Int]?,
    recurrenceEndDate: Date?,
    context: ModelContext
  ) {
    todo.title = title
    todo.notes = notes
    todo.priorityEnum = priority
    todo.dueDate = dueDate
    todo.reminderInterval = reminderInterval
    todo.category = category
    todo.recurrenceTypeEnum = recurrenceType
    todo.recurrenceInterval = recurrenceInterval
    todo.recurrenceDaysOfWeek = recurrenceDaysOfWeek
    todo.recurrenceEndDate = recurrenceEndDate
    try? context.save()

    NotificationService.shared.cancelTodoNotification(id: todo.id)
    if dueDate != nil && reminderInterval != nil {
      NotificationService.shared.scheduleTodoNotification(todo: todo)
    }
  }

  func deleteTodo(_ todo: TodoItem, context: ModelContext) {
    NotificationService.shared.cancelTodoNotification(id: todo.id)
    context.delete(todo)
    try? context.save()
  }

  func toggleCompletion(_ todo: TodoItem, context: ModelContext) {
    todo.isCompleted.toggle()

    if todo.isCompleted {
      todo.completedAt = Date()
      NotificationService.shared.cancelTodoNotification(id: todo.id)

      if todo.isRecurring, let nextDue = todo.nextDueDate() {
        let newTodo = TodoItem(
          title: todo.title,
          notes: todo.notes,
          priority: todo.priorityEnum,
          dueDate: nextDue,
          reminderInterval: todo.reminderInterval,
          category: todo.category,
          parentTodo: nil,
          recurrenceType: todo.recurrenceTypeEnum,
          recurrenceInterval: todo.recurrenceInterval,
          recurrenceDaysOfWeek: todo.recurrenceDaysOfWeek,
          recurrenceEndDate: todo.recurrenceEndDate
        )
        context.insert(newTodo)

        if let subtasks = todo.subtasks {
          for subtask in subtasks {
            let newSubtask = TodoItem(
              title: subtask.title,
              notes: subtask.notes,
              priority: subtask.priorityEnum,
              dueDate: nil,
              reminderInterval: nil,
              category: nil,
              parentTodo: newTodo
            )
            context.insert(newSubtask)
          }
        }

        if newTodo.reminderInterval != nil {
          NotificationService.shared.scheduleTodoNotification(todo: newTodo)
        }
      }
    } else {
      todo.completedAt = nil
      if todo.dueDate != nil && todo.reminderInterval != nil {
        NotificationService.shared.scheduleTodoNotification(todo: todo)
      }
    }

    try? context.save()
  }

  func addSubtask(to parent: TodoItem, title: String, context: ModelContext) {
    let subtask = TodoItem(
      title: title,
      priority: parent.priorityEnum,
      parentTodo: parent
    )
    context.insert(subtask)
    try? context.save()
  }

  func createDefaultCategoryIfNeeded(context: ModelContext) {
    let descriptor = FetchDescriptor<TodoCategory>(
      predicate: #Predicate { $0.name == "No Category" }
    )

    do {
      let existing = try context.fetch(descriptor)
      if existing.isEmpty {
        let defaultCategory = TodoCategory(name: TodoViewModel.noCategoryName, color: "gray")
        context.insert(defaultCategory)
        try? context.save()
      }
    } catch {
      let defaultCategory = TodoCategory(name: TodoViewModel.noCategoryName, color: "gray")
      context.insert(defaultCategory)
      try? context.save()
    }
  }

  func cleanupCompletedTodos(context: ModelContext) {
    let calendar = Calendar.current
    let now = Date()

    guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return }

    let descriptor = FetchDescriptor<TodoItem>(
      predicate: #Predicate { todo in
        todo.isCompleted == true && todo.parentTodo == nil
      }
    )

    do {
      let completedTodos = try context.fetch(descriptor)
      for todo in completedTodos {
        if let completedAt = todo.completedAt, completedAt < startOfWeek {
          context.delete(todo)
        }
      }
      try? context.save()
    } catch {}
  }

  func rescheduleAllNotifications(context: ModelContext) {
    let now = Date()
    let descriptor = FetchDescriptor<TodoItem>(
      predicate: #Predicate { todo in
        todo.isCompleted == false && todo.parentTodo == nil
      }
    )

    do {
      let todos = try context.fetch(descriptor)
      let todosWithReminders = todos.filter { todo in
        guard let dueDate = todo.dueDate,
          let reminder = todo.reminderInterval,
          reminder > 0
        else { return false }
        let notifyDate = dueDate.addingTimeInterval(-reminder)
        return notifyDate > now
      }
      NotificationService.shared.syncTodoNotifications(todos: todosWithReminders)
    } catch {}
  }
}
