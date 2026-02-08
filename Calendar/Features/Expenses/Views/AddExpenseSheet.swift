import SwiftUI

struct AddExpenseSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let expense: Expense?
  let onSave: ((String, Double, Date, ExpenseCategory, PaymentMethod, String?, String?) -> Void)?
  let onDelete: (() -> Void)?

  @State private var title: String = ""
  @State private var amountText: String = ""
  @State private var date: Date = Date()
  @State private var category: ExpenseCategory = .other
  @State private var paymentMethod: PaymentMethod = .card
  @State private var merchant: String = ""
  @State private var notes: String = ""

  private let viewModel = ExpenseViewModel()

  init(
    expense: Expense? = nil,
    onSave: ((String, Double, Date, ExpenseCategory, PaymentMethod, String?, String?) -> Void)? =
      nil,
    onDelete: (() -> Void)? = nil
  ) {
    self.expense = expense
    self.onSave = onSave
    self.onDelete = onDelete

    if let expense = expense {
      _title = State(initialValue: expense.title)
      _amountText = State(initialValue: String(format: "%.2f", expense.amount))
      _date = State(initialValue: expense.date)
      _category = State(initialValue: expense.categoryEnum)
      _paymentMethod = State(initialValue: expense.paymentMethodEnum)
      _merchant = State(initialValue: expense.merchant ?? "")
      _notes = State(initialValue: expense.notes ?? "")
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField(Localization.string(.title), text: $title)

          HStack {
            Text("$")
              .foregroundColor(.textSecondary)
            TextField(Localization.string(.expenseAmount), text: $amountText)
              .keyboardType(.decimalPad)
          }
        }

        Section(Localization.string(.date)) {
          DatePicker(
            Localization.string(.date), selection: $date,
            displayedComponents: [.date]
          )
        }

        Section(Localization.string(.expenseCategory)) {
          Picker(Localization.string(.expenseCategory), selection: $category) {
            ForEach(ExpenseCategory.allCases) { cat in
              HStack {
                Image(systemName: cat.icon)
                  .foregroundColor(cat.color)
                Text(cat.displayName)
              }
              .tag(cat)
            }
          }
        }

        Section(Localization.string(.expensePaymentMethod)) {
          Picker(Localization.string(.expensePaymentMethod), selection: $paymentMethod) {
            ForEach(PaymentMethod.allCases, id: \.self) { method in
              HStack {
                Image(systemName: method.icon)
                Text(method.displayName)
              }
              .tag(method)
            }
          }
          .pickerStyle(.segmented)
        }

        Section {
          TextField(Localization.string(.expenseMerchant), text: $merchant)

          if #available(iOS 16.0, *) {
            TextField(Localization.string(.notes), text: $notes, axis: .vertical)
              .lineLimit(3...6)
          } else {
            TextField(Localization.string(.notes), text: $notes)
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
      .navigationTitle(
        expense == nil
          ? Localization.string(.expenseAdd)
          : Localization.string(.expenseEdit))
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Localization.string(.cancel)) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(Localization.string(.save)) {
            save()
          }
          .disabled(title.isEmpty || amountText.isEmpty)
        }
      }
    }
  }

  private func save() {
    guard let amount = Double(amountText) else { return }

    if let onSave = onSave {
      onSave(
        title, amount, date, category, paymentMethod,
        merchant.isEmpty ? nil : merchant,
        notes.isEmpty ? nil : notes
      )
    } else if let expense = expense {
      viewModel.updateExpense(
        expense, title: title, amount: amount, date: date,
        category: category, paymentMethod: paymentMethod,
        merchant: merchant.isEmpty ? nil : merchant,
        notes: notes.isEmpty ? nil : notes,
        context: modelContext
      )
    } else {
      viewModel.addExpense(
        title: title, amount: amount, date: date,
        category: category, paymentMethod: paymentMethod,
        merchant: merchant.isEmpty ? nil : merchant,
        notes: notes.isEmpty ? nil : notes,
        context: modelContext
      )
    }
    dismiss()
  }
}
