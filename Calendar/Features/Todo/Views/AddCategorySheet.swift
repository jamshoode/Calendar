import SwiftUI

struct AddCategorySheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme

  let category: TodoCategory?
  let onSave: (String, String) -> Void
  let onDelete: (() -> Void)?

  @State private var name: String = ""
  @State private var selectedColor: String = "blue"

  private let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "gray"]

  init(
    category: TodoCategory? = nil, onSave: @escaping (String, String) -> Void,
    onDelete: (() -> Void)? = nil
  ) {
    self.category = category
    self.onSave = onSave
    self.onDelete = onDelete

    if let category = category {
      _name = State(initialValue: category.name)
      _selectedColor = State(initialValue: category.color)
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField(Localization.string(.categoryName), text: $name)
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
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Localization.string(.cancel)) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(category == nil ? Localization.string(.save) : Localization.string(.update)) {
            onSave(name, selectedColor)
            dismiss()
          }
          .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }
    }
  }
}
