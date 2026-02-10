import SwiftData
import SwiftUI

struct ExpensesView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Expense.date) private var expenses: [Expense]
  @State private var selectedPeriod: ExpensePeriod = .monthly
  @State private var showingAddExpense = false
  @State private var editingExpense: Expense? = nil

  private let viewModel = ExpenseViewModel()

  enum ExpensePeriod: String, CaseIterable {
    case weekly, monthly, yearly

    var displayName: String {
      switch self {
      case .weekly: return Localization.string(.expenseWeekly)
      case .monthly: return Localization.string(.expenseMonthly)
      case .yearly: return Localization.string(.expenseYearly)
      }
    }
  }

  // MARK: - Computed helpers

  private var filteredExpenses: [Expense] {
    let bounds = periodBounds(for: selectedPeriod)
    return expenses.filter { $0.date >= bounds.start && $0.date <= bounds.end }
  }

  private func periodBounds(for period: ExpensePeriod) -> (start: Date, end: Date) {
    let calendar = Calendar.current
    let today = Date()
    let interval: DateInterval

    switch period {
    case .weekly:
      interval =
        calendar.dateInterval(of: .weekOfYear, for: today) ?? DateInterval(start: today, end: today)
    case .monthly:
      interval =
        calendar.dateInterval(of: .month, for: today) ?? DateInterval(start: today, end: today)
    case .yearly:
      interval =
        calendar.dateInterval(of: .year, for: today) ?? DateInterval(start: today, end: today)
    }

    let start = interval.start
    let end = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
    return (start, end)
  }

  var body: some View {
    VStack(spacing: 0) {
      // Period Selector
      Picker("Period", selection: $selectedPeriod) {
        ForEach(ExpensePeriod.allCases, id: \.self) { period in
          Text(period.displayName).tag(period)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, Spacing.md)
      .padding(.top, Spacing.sm)

      ScrollView {
        VStack(spacing: Spacing.sectionSpacing) {
          // Total amount card (for selected period)
          let bounds = periodBounds(for: selectedPeriod)
          let totalAmount = viewModel.totalForPeriod(
            expenses: filteredExpenses, start: bounds.start, end: bounds.end)

          let totalCurrencySymbol =
            filteredExpenses.first?.currencyEnum.symbol ?? Currency.usd.symbol

          VStack(spacing: Spacing.xs) {
            Text(Localization.string(.expenseTotal))
              .font(Typography.caption)
              .foregroundColor(.textSecondary)
            Text("\(totalCurrencySymbol)\(String(format: "%.2f", totalAmount))")
              .font(.system(size: 36, weight: .bold, design: .rounded))
              .foregroundColor(.textPrimary)
          }
          .frame(maxWidth: .infinity)
          .padding(Spacing.xl)
          .cardStyle()

          if filteredExpenses.isEmpty {
            // Empty state
            VStack(spacing: Spacing.md) {
              Image(systemName: "dollarsign.circle")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)
              Text(Localization.string(.expenseNoExpenses))
                .font(Typography.headline)
                .foregroundColor(.textSecondary)
              Text(Localization.string(.expenseTapToAdd))
                .font(Typography.caption)
                .foregroundColor(.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.xxl)
          } else {
            // Grouped list by date
            ForEach(viewModel.groupedByDate(expenses: filteredExpenses), id: \.date) { group in
              VStack(alignment: .leading, spacing: 8) {
                Text(group.date.formatted(date: .abbreviated, time: .omitted))
                  .font(Typography.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.textTertiary)
                  .padding(.horizontal, 4)

                ForEach(group.expenses, id: \.id) { expense in
                  ExpenseRow(expense: expense)
                    .onTapGesture {
                      editingExpense = expense
                      showingAddExpense = true
                    }
                    .contextMenu {
                      Button {
                        editingExpense = expense
                        showingAddExpense = true
                      } label: {
                        Text(Localization.string(.edit))
                        Image(systemName: "pencil")
                      }

                      Button(role: .destructive) {
                        do {
                          try viewModel.deleteExpense(expense, context: modelContext)
                        } catch {
                          ErrorPresenter.presentOnMain(error)
                        }
                      } label: {
                        Text(Localization.string(.delete))
                        Image(systemName: "trash")
                      }
                    }
                }
              }
              .padding(.horizontal, 4)
              .padding(.vertical, 6)
            }
          }
        }
        .padding(Spacing.md)
      }
    }
    .background(Color.backgroundPrimary)
    .overlay(alignment: .bottomTrailing) {
      Button(action: {
        editingExpense = nil
        showingAddExpense = true
      }) {
        Image(systemName: "plus")
          .font(.system(size: 24, weight: .semibold))
          .foregroundColor(.white)
          .frame(width: 56, height: 56)
          .background(Color.accentColor)
          .clipShape(Circle())
          .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
      }
      .padding(.trailing, Spacing.lg)
      .padding(.bottom, Spacing.lg)
    }
    .sheet(isPresented: $showingAddExpense) {
      AddExpenseSheet(
        expense: editingExpense,
        onSave: { title, amount, date, category, paymentMethod, currency, merchant, notes in
          performSave(
            title: title, amount: amount, date: date, category: category,
            paymentMethod: paymentMethod, currency: currency,
            merchant: merchant, notes: notes)
        },

        onDelete: {
          performDelete()
        }
      )
    }
  }

  private func performSave(
    title: String, amount: Double, date: Date, category: ExpenseCategory,
    paymentMethod: PaymentMethod, currency: Currency, merchant: String?, notes: String?
  ) {
    do {
      if let editing = editingExpense {
        try viewModel.updateExpense(
          editing,
          title: title,
          amount: amount,
          date: date,
          category: category,
          paymentMethod: paymentMethod,
          currency: currency,
          merchant: merchant,
          notes: notes,
          context: modelContext
        )
        editingExpense = nil
      } else {
        try viewModel.addExpense(
          title: title,
          amount: amount,
          date: date,
          category: category,
          paymentMethod: paymentMethod,
          currency: currency,
          merchant: merchant,
          notes: notes,
          context: modelContext
        )
      }
      showingAddExpense = false
    } catch {
      ErrorPresenter.presentOnMain(error)
    }
  }

  private func performDelete() {
    if let editing = editingExpense {
      do {
        try viewModel.deleteExpense(editing, context: modelContext)
        editingExpense = nil
        showingAddExpense = false
      } catch {
        ErrorPresenter.presentOnMain(error)
      }
    }
  }
}
