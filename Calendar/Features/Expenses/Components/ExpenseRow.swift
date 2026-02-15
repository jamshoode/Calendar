import SwiftUI

struct ExpenseRow: View {
  let expense: Expense

  var body: some View {
    HStack(spacing: Spacing.sm) {
      // Category icon
      ZStack {
          Circle()
              .fill(expense.primaryCategory.color.opacity(0.15))
              .frame(width: 44, height: 44)
          
          Image(systemName: expense.primaryCategory.icon)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(expense.primaryCategory.color)
      }

      // Title & merchant
      VStack(alignment: .leading, spacing: 4) {
        Text(expense.title)
          .font(Typography.body)
          .fontWeight(.bold)
          .foregroundColor(.textPrimary)
          .lineLimit(1)

        if let merchant = expense.merchant, !merchant.isEmpty {
          Text(merchant.uppercased())
            .font(.system(size: 10, weight: .black))
            .tracking(1)
            .foregroundColor(.textTertiary)
        }
      }

      Spacer()

      // Amount & payment method
      VStack(alignment: .trailing, spacing: 4) {
        Text("\(expense.currencyEnum.symbol)\(String(format: "%.2f", expense.amount))")
          .font(.system(size: 18, weight: .black, design: .rounded))
          .foregroundColor(.textPrimary)

        HStack(spacing: 4) {
          Image(systemName: expense.paymentMethodEnum.icon)
            .font(.system(size: 10))
          Text(expense.paymentMethodEnum.displayName)
            .font(Typography.badge)
            .fontWeight(.bold)
        }
        .foregroundColor(.textSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
      }
    }
    .padding(12)
    .background(.ultraThinMaterial.opacity(0.5))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .glassHalo(cornerRadius: 16)
  }
}
