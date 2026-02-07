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
      Date?, [String], TimeInterval?, Date?
    ) -> Void
  let onDelete: (() -> Void)?

  @State private var title: String = ""
  @State private var notes: String = ""
  @State private var priority: Priority = .medium
  @State private var hasDueDate: Bool = false
  @State private var dueDate: Date = Date()
  @State private var reminderSelection: TimeInterval = 0
  @State private var selectedCategory: TodoCategory?
  @State private var recurrenceType: RecurrenceType?
  @State private var recurrenceInterval: Int = 1
  @State private var recurrenceEndDate: Date?
  @State private var subtaskTitles: [String] = []
  @State private var newSubtaskTitle: String = ""
  @State private var repeatReminderInterval: TimeInterval = 0
  @State private var repeatReminderStartDate: Date = Date()

  private var reminders: [(String, TimeInterval)] {
    [
      (Localization.string(.none), 0),
      (Localization.string(.atTimeOfEvent), 0.1),
      (Localization.string(.minutesBefore(15)), 15 * 60),
      (Localization.string(.minutesBefore(30)), 30 * 60),
      (Localization.string(.hoursBefore(1)), 60 * 60),
      (Localization.string(.hoursBefore(2)), 2 * 60 * 60),
      (Localization.string(.daysBefore(1)), 24 * 60 * 60),
    ]
  }

  init(
    todo: TodoItem? = nil,
    categories: [TodoCategory],
    onSave:
      @escaping (
        String, String?, Priority, Date?, TimeInterval?, TodoCategory?, RecurrenceType?, Int,
        [Int]?, Date?, [String], TimeInterval?, Date?
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
      _reminderSelection = State(initialValue: todo.reminderInterval ?? 0)
      _selectedCategory = State(initialValue: todo.category)
      _recurrenceType = State(initialValue: todo.recurrenceTypeEnum)
      _recurrenceInterval = State(initialValue: todo.recurrenceInterval)
      _recurrenceEndDate = State(initialValue: todo.recurrenceEndDate)
      _subtaskTitles = State(initialValue: todo.subtasks?.map { $0.title } ?? [])
      _repeatReminderInterval = State(initialValue: todo.reminderRepeatInterval ?? 0)
      _repeatReminderStartDate = State(initialValue: todo.dueDate ?? Date())
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField(Localization.string(.todoTitle), text: $title)

          if #available(iOS 16.0, *) {
            TextField(Localization.string(.notes), text: $notes, axis: .vertical)
              .lineLimit(3...6)
          } else {
            TextField(Localization.string(.notes), text: $notes)
          }
        }

        Section(Localization.string(.priority)) {
          Picker(Localization.string(.priority), selection: $priority) {
            ForEach(Priority.allCases, id: \.self) { p in
              Text(p.displayName).tag(p)
            }
          }
          .pickerStyle(.segmented)
        }

        Section(Localization.string(.category)) {
          Picker(Localization.string(.category), selection: $selectedCategory) {
            Text(Localization.string(.noCategory)).tag(nil as TodoCategory?)
            ForEach(categories.filter { $0.name != TodoViewModel.noCategoryName }) { cat in
              HStack {
                Circle()
                  .fill(Color.eventColor(named: cat.color))
                  .frame(width: 10, height: 10)
                Text(cat.name)
              }
              .tag(cat as TodoCategory?)
            }
          }
        }

        Section(Localization.string(.dueDate)) {
          Toggle(Localization.string(.hasDueDate), isOn: $hasDueDate)

          if hasDueDate {
            DatePicker(
              Localization.string(.dueDate), selection: $dueDate,
              displayedComponents: [.date, .hourAndMinute])

            Picker(Localization.string(.reminder), selection: $reminderSelection) {
              ForEach(reminders, id: \.1) { label, value in
                Text(label).tag(value)
              }
            }

            // Repeat reminder every N minutes until due date
            Picker(Localization.string(.repeatReminder), selection: $repeatReminderInterval) {
              Text(Localization.string(.repeatReminderOff)).tag(TimeInterval(0))
              Text(Localization.string(.everyNMinutes(15))).tag(TimeInterval(15 * 60))
              Text(Localization.string(.everyNMinutes(30))).tag(TimeInterval(30 * 60))
              Text(Localization.string(.everyNMinutes(45))).tag(TimeInterval(45 * 60))
              Text(Localization.string(.everyNMinutes(60))).tag(TimeInterval(60 * 60))
            }

            if repeatReminderInterval > 0 {
              DatePicker(
                Localization.string(.repeatReminderFromDate),
                selection: $repeatReminderStartDate,
                displayedComponents: [.date, .hourAndMinute]
              )
            }
          }
        }

        if hasDueDate {
          Section(Localization.string(.recurring)) {
            RecurrencePicker(
              recurrenceType: $recurrenceType,
              interval: $recurrenceInterval,
              endDate: $recurrenceEndDate
            )
          }
        }

        Section(Localization.string(.subtasks)) {
          ForEach(subtaskTitles.indices, id: \.self) { index in
            HStack {
              Image(systemName: "circle")
                .foregroundColor(.secondary)
              Text(subtaskTitles[index])
              Spacer()
              Button(action: { subtaskTitles.remove(at: index) }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.secondary)
              }
              .buttonStyle(.plain)
            }
          }

          HStack {
            TextField(Localization.string(.addSubtask), text: $newSubtaskTitle)

            Button(action: addSubtask) {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
          }
        }

        if let onDelete = onDelete {
          Section {
            Button(role: .destructive) {
              onDelete()
              dismiss()
            } label: {
              HStack {
                Spacer()
                Text(Localization.string(.delete))
                Spacer()
              }
            }
          }
        }
      }
      .navigationTitle(todo == nil ? Localization.string(.addTodo) : Localization.string(.editTodo))
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Localization.string(.cancel)) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(todo == nil ? Localization.string(.save) : Localization.string(.update)) {
            saveTodo()
          }
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

  private func saveTodo() {
    let repeatInterval = hasDueDate && repeatReminderInterval > 0 ? repeatReminderInterval : nil
    let repeatStart = hasDueDate && repeatReminderInterval > 0 ? repeatReminderStartDate : nil
    onSave(
      title,
      notes.isEmpty ? nil : notes,
      priority,
      hasDueDate ? dueDate : nil,
      hasDueDate && reminderSelection > 0 ? reminderSelection : nil,
      selectedCategory,
      hasDueDate ? recurrenceType : nil,
      recurrenceInterval,
      nil,
      recurrenceEndDate,
      subtaskTitles,
      repeatInterval,
      repeatStart
    )
    dismiss()
  }
}
