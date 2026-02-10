import SwiftUI

struct ExpenseRow: View {
  let expense: Expense

  var body: some View {
    HStack(spacing: Spacing.sm) {
      // Category icon
      Image(systemName: expense.categoryEnum.icon)
        .font(.system(size: 16))
        .foregroundColor(expense.categoryEnum.color)
        .frame(width: 36, height: 36)
        .background(expense.categoryEnum.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))

      // Title & merchant
      VStack(alignment: .leading, spacing: 2) {
        Text(expense.title)
          .font(Typography.headline)
          .foregroundColor(.textPrimary)
          .lineLimit(1)

        if let merchant = expense.merchant, !merchant.isEmpty {
          Text(merchant)
            .font(Typography.caption)
            .foregroundColor(.textSecondary)
        }
      }

      Spacer()

      // Amount & payment method
      VStack(alignment: .trailing, spacing: 2) {
        Text("\(expense.currencyEnum.symbol)\(String(format: "%.2f", expense.amount))")
          .font(Typography.headline)
          .foregroundColor(.textPrimary)

        HStack(spacing: 4) {
          Image(systemName: expense.paymentMethodEnum.icon)
            .font(.system(size: 10))
          Text(expense.paymentMethodEnum.displayName)
            .font(Typography.badge)
        }
        .foregroundColor(.textTertiary)
      }
    }
    .padding(Spacing.sm)
    .background(Color.surfaceCard)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
    .overlay(
      RoundedRectangle(cornerRadius: Spacing.smallRadius)
        .stroke(Color.border, lineWidth: 0.5)
    )
  }
}
