import SwiftData
import SwiftUI

struct AddTodoSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let todo: TodoItem?
  let categories: [TodoCategory]
  let onSave:
    (
      String, String?, Priority, Date?, TimeInterval?, TodoCategory?, RecurrenceType?, Int, [Int]?,
      Date?, [String], TimeInterval?, Int?
    ) -> Void
  let onDelete: (() -> Void)?

  @State private var title: String = ""
  @State private var notes: String = ""
  @State private var priority: Priority = .medium
  @State private var hasDueDate: Bool = false
  @State private var dueDate: Date = Date()
  @State private var reminderEnabled: Bool = false
  @State private var selectedCategoryId: UUID?
  @State private var recurrenceType: RecurrenceType?
  @State private var recurrenceInterval: Int = 1
  @State private var recurrenceEndDate: Date?
  @State private var subtaskTitles: [String] = []
  @State private var newSubtaskTitle: String = ""
  @State private var repeatReminderInterval: TimeInterval = 0
  @State private var repeatReminderCount: Int = 3

  init(
    todo: TodoItem? = nil,
    categories: [TodoCategory],
    onSave:
      @escaping (
        String, String?, Priority, Date?, TimeInterval?, TodoCategory?, RecurrenceType?, Int,
        [Int]?, Date?, [String], TimeInterval?, Int?
      ) -> Void,
    onDelete: (() -> Void)? = nil
  ) {
    self.todo = todo
    self.categories = categories
    self.onSave = onSave
    self.onDelete = onDelete

    if let todo = todo {
      _title = State(initialValue: todo.title)
      _notes = State(initialValue: todo.notes ?? "")
      _priority = State(initialValue: todo.priorityEnum)
      _hasDueDate = State(initialValue: todo.dueDate != nil)
      _dueDate = State(initialValue: todo.dueDate ?? Date())
      _reminderEnabled = State(initialValue: (todo.reminderInterval ?? 0) > 0)
      _selectedCategoryId = State(initialValue: todo.category?.id)
      _recurrenceType = State(initialValue: todo.recurrenceTypeEnum)
      _recurrenceInterval = State(initialValue: todo.recurrenceInterval)
      _recurrenceEndDate = State(initialValue: todo.recurrenceEndDate)
      _subtaskTitles = State(initialValue: todo.subtasks?.map { $0.title } ?? [])
      _repeatReminderInterval = State(initialValue: todo.reminderRepeatInterval ?? 0)
      _repeatReminderCount = State(initialValue: todo.reminderRepeatCount ?? 3)
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        // Subtle background blending
        MeshGradientView()
          .ignoresSafeArea()
          .opacity(0.4)
          
        ScrollView {
          VStack(spacing: 20) {
            // Main Info
            GlassCard(cornerRadius: 24, material: .thin) {
              VStack(spacing: 16) {
                TextField(Localization.string(.todoTitle), text: $title)
                  .font(Typography.headline)
                  .textFieldStyle(.plain)
                
                Divider()
                
                TextField(Localization.string(.notes), text: $notes, axis: .vertical)
                  .font(Typography.body)
                  .textFieldStyle(.plain)
                  .lineLimit(3...6)
              }
              .padding(4)
            }
            
            // Priority & Category
            HStack(spacing: 16) {
              GlassCard(cornerRadius: 20, material: .thin) {
                VStack(alignment: .leading, spacing: 10) {
                  Text(Localization.string(.priority).uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.textTertiary)
                  
                  Picker(Localization.string(.priority), selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                      Text(p.displayName).tag(p)
                    }
                  }
                  .pickerStyle(.menu)
                  .labelsHidden()
                }
              }
              
              GlassCard(cornerRadius: 20, material: .thin) {
                VStack(alignment: .leading, spacing: 10) {
                  Text(Localization.string(.category).uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.textTertiary)
                  
                  Picker(Localization.string(.category), selection: $selectedCategoryId) {
                    Text(Localization.string(.noCategory)).tag(nil as UUID?)
                    ForEach(flattenedCategories(categories)) { cat in
                      Text(cat.name).tag(cat.id as UUID?)
                    }
                  }
                  .pickerStyle(.menu)
                  .labelsHidden()
                }
              }
            }
            
            // Due Date & Reminders
            GlassCard(cornerRadius: 24, material: .thin) {
              VStack(spacing: 16) {
                Toggle(Localization.string(.hasDueDate), isOn: $hasDueDate)
                  .font(Typography.body)
                  .fontWeight(.bold)
                
                if hasDueDate {
                  Divider()
                  DatePicker(
                    Localization.string(.dueDate), selection: $dueDate,
                    displayedComponents: [.date, .hourAndMinute])
                  
                  Divider()
                  Toggle(Localization.string(.reminder), isOn: $reminderEnabled)
                    .font(Typography.body)
                    .fontWeight(.medium)
                }
              }
            }
            
            // Subtasks
            GlassCard(cornerRadius: 24, material: .thin) {
              VStack(alignment: .leading, spacing: 12) {
                Text(Localization.string(.subtasks).uppercased())
                  .font(.system(size: 10, weight: .black))
                  .foregroundColor(.textTertiary)
                
                ForEach(subtaskTitles.indices, id: \.self) { index in
                  HStack {
                    Image(systemName: "circle")
                      .foregroundColor(.accentColor)
                    Text(subtaskTitles[index])
                    Spacer()
                    Button(action: { subtaskTitles.remove(at: index) }) {
                      Image(systemName: "minus.circle.fill")
                        .foregroundColor(.textTertiary)
                    }
                  }
                  .padding(.vertical, 4)
                }
                
                HStack {
                  TextField(Localization.string(.addSubtask), text: $newSubtaskTitle)
                    .textFieldStyle(.plain)
                  
                  Button(action: addSubtask) {
                    Image(systemName: "plus.circle.fill")
                      .font(.system(size: 20))
                      .foregroundColor(.accentColor)
                  }
                  .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
              }
            }
            
            if let onDelete = onDelete {
              Button(role: .destructive) {
                onDelete()
                dismiss()
              } label: {
                Text(Localization.string(.delete))
                  .font(Typography.body)
                  .fontWeight(.bold)
                  .foregroundColor(.red)
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(.ultraThinMaterial)
                  .clipShape(RoundedRectangle(cornerRadius: 16))
              }
              .padding(.top, 10)
            }
          }
          .padding(20)
        }
      }
      .navigationTitle(todo == nil ? Localization.string(.addTodo) : Localization.string(.editTodo))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Localization.string(.cancel)) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(todo == nil ? Localization.string(.save) : Localization.string(.update)) {
            saveTodo()
          }
          .fontWeight(.bold)
          .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }
    }
  }

  private func addSubtask() {
    let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
    if !trimmed.isEmpty {
      subtaskTitles.append(trimmed)
      newSubtaskTitle = ""
    }
  }

  private func flattenedCategories(_ categories: [TodoCategory]) -> [TodoCategory] {
    let roots = categories.filter { $0.parent == nil && $0.name != TodoViewModel.noCategoryName }
      .sorted { $0.sortOrder < $1.sortOrder }
    var result: [TodoCategory] = []
    for root in roots {
      result.append(contentsOf: getCategoryHierarchy(root))
    }
    return result
  }

  private func getCategoryHierarchy(_ category: TodoCategory) -> [TodoCategory] {
    var result = [category]
    if let subcats = category.subcategories {
      for subcat in subcats.sorted(by: { $0.sortOrder < $1.sortOrder }) {
        result.append(contentsOf: getCategoryHierarchy(subcat))
      }
    }
    return result
  }

  private func saveTodo() {
    let repeatInterval =
      hasDueDate && reminderEnabled && repeatReminderInterval > 0 ? repeatReminderInterval : nil
    let repeatCount =
      hasDueDate && reminderEnabled && repeatReminderInterval > 0 ? repeatReminderCount : nil
    let selectedCategory = categories.first(where: { $0.id == selectedCategoryId })
    onSave(
      title,
      notes.isEmpty ? nil : notes,
      priority,
      hasDueDate ? dueDate : nil,
      hasDueDate && reminderEnabled ? 0.1 : nil,
      selectedCategory,
      hasDueDate ? recurrenceType : nil,
      recurrenceInterval,
      nil,
      recurrenceEndDate,
      subtaskTitles,
      repeatInterval,
      repeatCount
    )
    dismiss()
  }
}
