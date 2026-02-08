import SwiftUI

struct ExpensesView: View {
  @State private var selectedPeriod: ExpensePeriod = .monthly
  @State private var showingAddExpense = false

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

      // Placeholder content
      ScrollView {
        VStack(spacing: Spacing.sectionSpacing) {
          // Total amount card
          VStack(spacing: Spacing.xs) {
            Text(Localization.string(.expenseTotal))
              .font(Typography.caption)
              .foregroundColor(.textSecondary)
            Text("$0.00")
              .font(.system(size: 36, weight: .bold, design: .rounded))
              .foregroundColor(.textPrimary)
          }
          .frame(maxWidth: .infinity)
          .padding(Spacing.xl)
          .cardStyle()

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
        }
        .padding(Spacing.md)
      }
    }
    .background(Color.backgroundPrimary)
    .overlay(alignment: .bottomTrailing) {
      Button(action: { showingAddExpense = true }) {
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
      AddExpenseSheet()
    }
  }
}
