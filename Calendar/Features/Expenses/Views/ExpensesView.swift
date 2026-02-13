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

  private var filteredExpenses: [Expense] {
    let bounds = periodBounds(for: selectedPeriod)
    return expenses.filter { $0.date >= bounds.start && $0.date <= bounds.end }
  }

  private func periodBounds(for period: ExpensePeriod) -> (start: Date, end: Date) {
    let calendar = Calendar.current
    let today = Date()
    let interval: DateInterval
    switch period {
    case .weekly: interval = calendar.dateInterval(of: .weekOfYear, for: today) ?? DateInterval(start: today, end: today)
    case .monthly: interval = calendar.dateInterval(of: .month, for: today) ?? DateInterval(start: today, end: today)
    case .yearly: interval = calendar.dateInterval(of: .year, for: today) ?? DateInterval(start: today, end: today)
    }
    return (interval.start, calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end)
  }

  var body: some View {
    VStack(spacing: 0) {
      // Atmospheric Header
      VStack(spacing: 16) {
          Text(Localization.string(.tabExpenses).uppercased())
              .font(.system(size: 14, weight: .black))
              .tracking(2)
              .foregroundColor(.textSecondary)
          
          // Custom Glass Period Picker
          HStack(spacing: 0) {
              ForEach(ExpensePeriod.allCases, id: \.self) { period in
                  Button {
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                          selectedPeriod = period
                      }
                  } label: {
                      Text(period.displayName)
                          .font(.system(size: 13, weight: .bold))
                          .foregroundColor(selectedPeriod == period ? .white : .textSecondary)
                          .frame(maxWidth: .infinity)
                          .frame(height: 36)
                          .background(selectedPeriod == period ? Color.accentColor : Color.clear)
                          .clipShape(RoundedRectangle(cornerRadius: 10))
                  }
                  .buttonStyle(.plain)
              }
          }
          .padding(4)
          .background(.ultraThinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 14))
          .glassHalo(cornerRadius: 14)
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 10)

      ScrollView {
        VStack(spacing: 24) {
          // Hero Total Amount
          let bounds = periodBounds(for: selectedPeriod)
          let totalAmount = viewModel.totalForPeriod(expenses: filteredExpenses, start: bounds.start, end: bounds.end)
          let totalCurrencySymbol = filteredExpenses.first?.currencyEnum.symbol ?? "$"

          VStack(spacing: 8) {
            Text(Localization.string(.total).uppercased())
              .font(.system(size: 10, weight: .black))
              .foregroundColor(.textTertiary)
              .tracking(2)
            
            Text("\(totalCurrencySymbol)\(String(format: "%.2f", totalAmount))")
              .font(.system(size: 48, weight: .black, design: .rounded))
              .foregroundColor(.textPrimary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 30)
          .background(
              ZStack {
                  Circle()
                      .fill(Color.accentColor.opacity(0.1))
                      .frame(width: 200, height: 200)
                      .blur(radius: 50)
              }
          )

          if filteredExpenses.isEmpty {
            VStack(spacing: 20) {
              Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)
              Text(Localization.string(.expenseNoExpenses))
                .font(Typography.body)
                .foregroundColor(.textSecondary)
            }
            .padding(.top, 40)
          } else {
            ForEach(viewModel.groupedByDate(expenses: filteredExpenses), id: \.date) { group in
              VStack(alignment: .leading, spacing: 12) {
                Text(group.date.formatted(date: .abbreviated, time: .omitted).uppercased())
                  .font(.system(size: 10, weight: .black))
                  .foregroundColor(.textTertiary)
                  .padding(.leading, 4)

                ForEach(group.expenses, id: \.id) { expense in
                  ExpenseRow(expense: expense)
                    .onTapGesture {
                      editingExpense = expense
                      showingAddExpense = true
                    }
                }
              }
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 120)
      }
    }
    .overlay(alignment: .bottomTrailing) {
      Button(action: {
        editingExpense = nil
        showingAddExpense = true
      }) {
        Image(systemName: "plus")
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.white)
          .frame(width: 60, height: 60)
          .background(Color.accentColor)
          .clipShape(Circle())
          .shadow(color: Color.accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
      }
      .padding(.trailing, 24)
      .padding(.bottom, 100)
    }
    .sheet(isPresented: $showingAddExpense) {
      AddExpenseSheet(
        expense: editingExpense,
        onSave: { title, amount, date, category, paymentMethod, currency, merchant, notes in
          do {
            if let expense = editingExpense {
              try viewModel.updateExpense(expense, title: title, amount: amount, date: date, category: category, paymentMethod: paymentMethod, currency: currency, merchant: merchant, notes: notes, context: modelContext)
            } else {
              try viewModel.addExpense(title: title, amount: amount, date: date, category: category, paymentMethod: paymentMethod, currency: currency, merchant: merchant, notes: notes, context: modelContext)
            }
          } catch {
            ErrorPresenter.shared.present(error)
          }
        },
        onDelete: {
          if let expense = editingExpense {
            try? viewModel.deleteExpense(expense, context: modelContext)
          }
        }
      )
    }
  }
}
