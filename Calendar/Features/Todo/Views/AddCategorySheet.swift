import SwiftUI

struct AddCategorySheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme

  let category: TodoCategory?
  let categories: [TodoCategory]
  let onSave: (String, String, TodoCategory?) -> Void
  let onDelete: (() -> Void)?

  @State private var name: String = ""
  @State private var selectedColor: String = "blue"
  @State private var parentCategory: TodoCategory?

  private let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "gray"]

  init(
    category: TodoCategory? = nil,
    categories: [TodoCategory] = [],
    onSave: @escaping (String, String, TodoCategory?) -> Void,
    onDelete: (() -> Void)? = nil
  ) {
    self.category = category
    self.categories = categories
    self.onSave = onSave
    self.onDelete = onDelete

    if let category = category {
      _name = State(initialValue: category.name)
      _selectedColor = State(initialValue: category.color)
      _parentCategory = State(initialValue: category.parent)
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField(Localization.string(.categoryName), text: $name)

          Picker(Localization.string(.parentCategory), selection: $parentCategory) {
            Text(Localization.string(.none)).tag(Optional<TodoCategory>.none)
            ForEach(
              categories.filter { $0.id != category?.id && $0.name != TodoViewModel.noCategoryName && $0.depth < 2 },
              id: \.id
            ) { cat in
              Text(cat.name).tag(Optional(cat))
            }
          }
        }

        Section(Localization.string(.color)) {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
              ForEach(colors, id: \.self) { color in
                Button(action: { selectedColor = color }) {
                  Circle()
                    .fill(Color.eventColor(named: color))
                    .frame(width: 40, height: 40)
                    .overlay(
                      Circle()
                        .stroke(
                          colorScheme == .dark
                            ? Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255) : .white,
                          lineWidth: selectedColor == color ? 3 : 0
                        )
                    )
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal, 4)
          }
        }

        if let onDelete = onDelete, category?.name != TodoViewModel.noCategoryName {
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
      .navigationTitle(
        category == nil ? Localization.string(.addCategory) : Localization.string(.editCategory)
      )
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
          Button(category == nil ? Localization.string(.save) : Localization.string(.update)) {
            onSave(name, selectedColor, parentCategory)
            dismiss()
          }
          .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }
    }
  }
}
