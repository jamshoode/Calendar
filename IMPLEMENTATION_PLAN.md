## Plan: Todo Feature Implementation

Implementing a full todo system as a new tab with categories, priorities, subtasks (1-level), recurring todos, and calendar integration. Uses floating action button for quick add, "No Category" default, and auto-creates next recurrence on completion.

### Implementation Guidelines

- **Don't mess things up** - Follow existing patterns exactly, test changes don't break current functionality
- **Keep project structure professional** - Match existing folder organization, naming conventions, and code style
- **No comments in code** - Only add comments when absolutely necessary for complex logic

### Steps

1. **Create data models** in Core/Models/:
   - `TodoCategory.swift` - `@Model` with `id: UUID`, `name: String`, `color: String`, `createdAt: Date`, `@Relationship` to `[TodoItem]`
   - `TodoItem.swift` - `@Model` with `id`, `title`, `isCompleted`, `completedAt: Date?`, `priority: String` (raw value of enum), `dueDate: Date?`, `reminderInterval: TimeInterval?`, `notes: String?`, `createdAt`, `category: TodoCategory?`, `parentTodo: TodoItem?`, `@Relationship` to `[TodoItem]` (subtasks), recurrence fields: `recurrenceType: String?`, `recurrenceInterval: Int`, `recurrenceDaysOfWeek: [Int]?`, `recurrenceEndDate: Date?`
   - Add `Priority` enum (high/medium/low) and `RecurrenceType` enum (weekly/monthly/yearly) in same file

2. **Create `TodoViewModel.swift`** in Core/ViewModels/:
   - `createCategory()`, `updateCategory()`, `deleteCategory()` 
   - `createTodo()`, `updateTodo()`, `deleteTodo()`, `toggleCompletion()` - on toggle, if recurring → spawn next occurrence immediately with new `dueDate`
   - `createDefaultCategoryIfNeeded()` - ensures "No Category" exists on first launch
   - `cleanupCompletedTodos()` - removes todos where `completedAt` is before start of current week
   - Call `NotificationService` for reminders when `dueDate` and `reminderInterval` set

3. **Add notification methods** in NotificationService.swift:
   - `scheduleTodoNotification(todo: TodoItem)` - schedule with `"todo-\(id)"` identifier
   - `cancelTodoNotification(id: UUID)` - cancel specific todo notification
   - `syncTodoNotifications(todos: [TodoItem])` - bulk sync pattern like events

4. **Create feature folder structure** `Features/Todo/`:
   - **Components/**: `TodoCheckbox.swift`, `PriorityBadge.swift`, `SubtaskRow.swift`, `RecurrencePicker.swift`
   - **Views/**: `TodoView.swift` (main tab), `CategoryCard.swift` (expandable category), `TodoRow.swift` (single todo with checkbox), `AddCategorySheet.swift`, `AddTodoSheet.swift` (full form with priority, due date, recurrence, subtasks)

5. **Implement main `TodoView.swift`**:
   - `@Query` categories and todos, `@StateObject` viewModel
   - List of `CategoryCard` components (expandable to show todos)
   - "No Category" section at top for uncategorized todos
   - Floating `+` button (bottom-right) → opens `AddTodoSheet`
   - On appear: call `createDefaultCategoryIfNeeded()` and `cleanupCompletedTodos()`

6. **Integrate with calendar** in CalendarView.swift:
   - Add `@Query` for `TodoItem` where `dueDate` is not nil
   - Modify `DayCell` to show todo indicator (different style from event indicator)
   - Modify `EventListView` to also display todos for selected date (with checkbox inline)

7. **Register in app**:
   - Add `TodoItem.self`, `TodoCategory.self` to `modelContainer` in CalendarApp.swift
   - Add `.todo` case to `Tab` enum in AppState.swift
   - Add todo tab in AdaptiveTabBar.swift with `checkmark.circle` icon
   - Add todo sidebar item in AdaptiveSidebar.swift
   - Add `TodoView()` case in macOS `MenuBarContentView` in CalendarApp.swift

8. **Add localization** in Localization.swift:
   - Keys: `tabTodo`, `addTodo`, `addCategory`, `editTodo`, `editCategory`, `noCategory`, `priority`, `priorityHigh`, `priorityMedium`, `priorityLow`, `dueDate`, `recurring`, `subtasks`, `addSubtask`, `noTodos`, `todosCount(Int)`, `weekly`, `monthly`, `yearly`, `everyNWeeks(Int)`, `everyNMonths(Int)`

### Data Model Details

```
TodoCategory
├── id: UUID
├── name: String
├── color: String  
├── createdAt: Date
└── todos: [TodoItem]  // @Relationship

TodoItem
├── id: UUID
├── title: String
├── notes: String?
├── isCompleted: Bool
├── completedAt: Date?  // For week-end cleanup
├── priority: String    // "high" | "medium" | "low"
├── dueDate: Date?      // Shows on calendar if set
├── reminderInterval: TimeInterval?
├── createdAt: Date
├── category: TodoCategory?  // nil = "No Category"
├── parentTodo: TodoItem?    // nil = top-level, set = subtask
├── subtasks: [TodoItem]     // @Relationship, 1-level only
├── recurrenceType: String?  // "weekly" | "monthly" | "yearly"
├── recurrenceInterval: Int  // e.g., every 2 weeks
├── recurrenceDaysOfWeek: [Int]?  // For weekly: [1,3,5] = Mon,Wed,Fri
└── recurrenceEndDate: Date?
```

### Recurrence Logic

When `toggleCompletion()` marks a recurring todo complete:
1. Set `isCompleted = true`, `completedAt = Date()`
2. Calculate next `dueDate` based on `recurrenceType` and `recurrenceInterval`
3. If next date is before `recurrenceEndDate` (or no end date): create new `TodoItem` copy with new `dueDate`, `isCompleted = false`
4. Original stays visible (strikethrough) until week-end cleanup

### File Creation Summary

| New File | Location |
|----------|----------|
| `TodoCategory.swift` | Core/Models/ |
| `TodoItem.swift` | Core/Models/ |
| `TodoViewModel.swift` | Core/ViewModels/ |
| `TodoView.swift` | Features/Todo/Views/ |
| `TodoRow.swift` | Features/Todo/Views/ |
| `CategoryCard.swift` | Features/Todo/Views/ |
| `AddTodoSheet.swift` | Features/Todo/Views/ |
| `AddCategorySheet.swift` | Features/Todo/Views/ |
| `TodoCheckbox.swift` | Features/Todo/Components/ |
| `PriorityBadge.swift` | Features/Todo/Components/ |
| `SubtaskRow.swift` | Features/Todo/Components/ |
| `RecurrencePicker.swift` | Features/Todo/Components/ |

### Files to Modify

| File | Changes |
|------|---------|
| CalendarApp.swift | Add models to container, add macOS menu bar tab |
| AppState.swift | Add `.todo` to Tab enum |
| AdaptiveTabBar.swift | Add Todo tab |
| AdaptiveSidebar.swift | Add Todo sidebar link |
| NotificationService.swift | Add todo notification methods |
| Localization.swift | Add ~20 new localization keys |
| CalendarView.swift | Query todos, show on calendar |
| DayCell.swift | Add todo indicator |
| EventListView.swift | Display todos alongside events |
