import SwiftData
import SwiftUI

struct AddExpenseSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let expense: Expense?
  let onSave:
    ((String, Double, Date, ExpenseCategory, PaymentMethod, Currency, String?, String?) -> Void)?
  let onDelete: (() -> Void)?

  @State private var title: String = ""
  @State private var amountText: String = ""
  @State private var date: Date = Date()
  @State private var category: ExpenseCategory = .other
  @State private var paymentMethod: PaymentMethod = .card
  @State private var currency: Currency = .usd
  @State private var merchant: String = ""
  @State private var notes: String = ""

  private let viewModel = ExpenseViewModel()

  init(
    expense: Expense? = nil,
    onSave: (
      (String, Double, Date, ExpenseCategory, PaymentMethod, Currency, String?, String?) -> Void
    )? =
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
      _currency = State(initialValue: expense.currencyEnum)
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
            Text(currency.symbol)
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

        Section(Localization.string(.expenseCurrency)) {
          HStack(spacing: 8) {
            ForEach(Currency.allCases, id: \.self) { c in
              Button {
                currency = c
              } label: {
                HStack(spacing: 8) {
                  Text(c.symbol)
                  Text(c.displayName)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(currency == c ? Color.accentColor.opacity(0.14) : Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
              .buttonStyle(.plain)
            }
          }
        }

        Section(Localization.string(.expensePaymentMethod)) {
          HStack(spacing: 8) {
            ForEach(PaymentMethod.allCases, id: \.self) { method in
              Button {
                paymentMethod = method
              } label: {
                HStack(spacing: 8) {
                  Image(systemName: method.icon)
                  Text(method.displayName)
                }
                .foregroundColor(paymentMethod == method ? .white : .textPrimary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(paymentMethod == method ? Color.accentColor : Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
              .buttonStyle(.plain)
            }
          }
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
          : Localization.string(.expenseEdit)
      )
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
        title, amount, date, category, paymentMethod, currency,
        merchant.isEmpty ? nil : merchant,
        notes.isEmpty ? nil : notes
      )
      dismiss()
    } else if let expense = expense {
      do {
        try viewModel.updateExpense(
          expense, title: title, amount: amount, date: date,
          category: category, paymentMethod: paymentMethod, currency: currency,
          merchant: merchant.isEmpty ? nil : merchant,
          notes: notes.isEmpty ? nil : notes,
          context: modelContext
        )
        dismiss()
      } catch {
        ErrorPresenter.presentOnMain(error)
      }
    } else {
      do {
        try viewModel.addExpense(
          title: title, amount: amount, date: date,
          category: category, paymentMethod: paymentMethod, currency: currency,
          merchant: merchant.isEmpty ? nil : merchant,
          notes: notes.isEmpty ? nil : notes,
          context: modelContext
        )
        dismiss()
      } catch {
        ErrorPresenter.presentOnMain(error)
      }
    }
  }
}
