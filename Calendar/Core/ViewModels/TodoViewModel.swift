import Combine
import SwiftData
import SwiftUI
import WidgetKit

class TodoViewModel: ObservableObject {

  static let noCategoryName = "No Category"

  func createCategory(name: String, color: String, parent: TodoCategory? = nil, context: ModelContext) {
    if let parent = parent, parent.depth >= 2 {
      ErrorPresenter.shared.present(message: "Cannot nest category deeper than 3 levels")
      return
    }

    let descriptor = FetchDescriptor<TodoCategory>()
    var existingCount = 0
    do {
      existingCount = try context.fetchCount(descriptor)
    } catch {
      ErrorPresenter.presentOnMain(error)
      existingCount = 0
    }
    let category = TodoCategory(name: name, color: color, sortOrder: existingCount)
    context.insert(category)
    category.parent = parent

    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
      return
    }
  }

  func updateCategory(
    _ category: TodoCategory, name: String, color: String, parent: TodoCategory? = nil,
    context: ModelContext
  ) {
    if let parent = parent {
      if parent.id == category.id {
        ErrorPresenter.shared.present(message: "A category cannot be its own parent")
        return
      }
      if parent.depth >= 2 {
        ErrorPresenter.shared.present(message: "Cannot nest category deeper than 3 levels")
        return
      }
      // Check for cycles (basic check: parent shouldn't be a descendant of category)
      var p: TodoCategory? = parent
      while let currentP = p {
        if currentP.id == category.id {
          ErrorPresenter.shared.present(message: "Circular nesting is not allowed")
          return
        }
        p = currentP.parent
      }
    }

    category.name = name
    category.color = color
    category.parent = parent
    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
    }
  }

  func moveCategory(
    _ category: TodoCategory, toParent newParent: TodoCategory?, context: ModelContext
  ) {
    updateCategory(
      category, name: category.name, color: category.color, parent: newParent, context: context)
  }

  func deleteCategory(_ category: TodoCategory, context: ModelContext) {
    context.delete(category)
    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
    }
  }

  func toggleCategoryPin(_ category: TodoCategory, context: ModelContext) {
    category.isPinned.toggle()
    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
    }
  }

  func toggleTodoPin(_ todo: TodoItem, context: ModelContext) {
    todo.isPinned.toggle()
    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
    }
  }

  func createTodo(
    title: String,
    notes: String?,
    priority: Priority,
    dueDate: Date?,
    reminderInterval: TimeInterval?,
    reminderRepeatInterval: TimeInterval?,
    reminderRepeatCount: Int?,
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
      reminderRepeatInterval: reminderRepeatInterval,
      reminderRepeatCount: reminderRepeatCount,
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

    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
      return
    }

    if dueDate != nil && (reminderInterval != nil || reminderRepeatInterval != nil) {
      NotificationService.shared.scheduleTodoNotification(todo: todo)
    }

    syncTodoCountToWidget(context: context)
    EventViewModel().syncEventsToWidget(context: context)
  }

  func updateTodo(
    _ todo: TodoItem,
    title: String,
    notes: String?,
    priority: Priority,
    dueDate: Date?,
    reminderInterval: TimeInterval?,
    reminderRepeatInterval: TimeInterval?,
    reminderRepeatCount: Int?,
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
    todo.reminderRepeatInterval = reminderRepeatInterval
    todo.reminderRepeatCount = reminderRepeatCount
    todo.category = category
    todo.recurrenceTypeEnum = recurrenceType
    todo.recurrenceInterval = recurrenceInterval
    todo.recurrenceDaysOfWeek = recurrenceDaysOfWeek
    todo.recurrenceEndDate = recurrenceEndDate
    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
      return
    }

    NotificationService.shared.cancelTodoNotification(id: todo.id)
    if dueDate != nil && (reminderInterval != nil || reminderRepeatInterval != nil) {
      NotificationService.shared.scheduleTodoNotification(todo: todo)
    }

    syncTodoCountToWidget(context: context)
    EventViewModel().syncEventsToWidget(context: context)
  }

  func deleteTodo(_ todo: TodoItem, context: ModelContext) {
    NotificationService.shared.cancelTodoNotification(id: todo.id)
    context.delete(todo)
    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
      return
    }
    syncTodoCountToWidget(context: context)
    EventViewModel().syncEventsToWidget(context: context)
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
          reminderRepeatInterval: todo.reminderRepeatInterval,
          reminderRepeatCount: todo.reminderRepeatCount,
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

        if newTodo.reminderInterval != nil || newTodo.reminderRepeatInterval != nil {
          NotificationService.shared.scheduleTodoNotification(todo: newTodo)
        }
      }
    } else {
      todo.completedAt = nil
      if todo.dueDate != nil && (todo.reminderInterval != nil || todo.reminderRepeatInterval != nil)
      {
        NotificationService.shared.scheduleTodoNotification(todo: todo)
      }
    }

    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
      return
    }
    syncTodoCountToWidget(context: context)
    EventViewModel().syncEventsToWidget(context: context)
  }

  func addSubtask(to parent: TodoItem, title: String, context: ModelContext) {
    let subtask = TodoItem(
      title: title,
      priority: parent.priorityEnum,
      parentTodo: parent
    )
    context.insert(subtask)
    do {
      try context.save()
    } catch {
      ErrorPresenter.shared.present(error)
    }
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
        do {
          try context.save()
        } catch {
          ErrorPresenter.shared.present(error)
        }
      }
    } catch {
      let defaultCategory = TodoCategory(name: TodoViewModel.noCategoryName, color: "gray")
      context.insert(defaultCategory)
      do {
        try context.save()
      } catch {
        ErrorPresenter.shared.present(error)
      }
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
      do {
        try context.save()
      } catch {
        ErrorPresenter.shared.present(error)
      }
    } catch {
      ErrorPresenter.shared.present(error)
    }
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
    } catch {
      ErrorPresenter.shared.present(error)
    }
  }

  func syncTodoCountToWidget(context: ModelContext) {
    let descriptor = FetchDescriptor<TodoItem>(
      predicate: #Predicate { todo in
        todo.isCompleted == false && todo.parentTodo == nil
      }
    )
    var count = 0
    do {
      count = try context.fetchCount(descriptor)
    } catch {
      ErrorPresenter.shared.present(error)
      count = 0
    }
    let defaults = UserDefaults(suiteName: "group.com.shoode.calendar")
    defaults?.set(count, forKey: "incompleteTodoCount")
    defaults?.synchronize()
    WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
  }
}
