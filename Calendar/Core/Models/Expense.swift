import Foundation
import SwiftData

@Model
class Expense {
  var id: UUID
  var title: String
  var amount: Double
  var date: Date
  var category: String  // ExpenseCategory rawValue
  var paymentMethod: String  // "cash" or "card"
  var merchant: String?
  var notes: String?
  var createdAt: Date

  var categoryEnum: ExpenseCategory {
    get { ExpenseCategory(rawValue: category) ?? .other }
    set { category = newValue.rawValue }
  }

  var paymentMethodEnum: PaymentMethod {
    get { PaymentMethod(rawValue: paymentMethod) ?? .card }
    set { paymentMethod = newValue.rawValue }
  }

  init(
    title: String,
    amount: Double,
    date: Date = Date(),
    category: ExpenseCategory = .other,
    paymentMethod: PaymentMethod = .card,
    merchant: String? = nil,
    notes: String? = nil
  ) {
    self.id = UUID()
    self.title = title
    self.amount = amount
    self.date = date
    self.category = category.rawValue
    self.paymentMethod = paymentMethod.rawValue
    self.merchant = merchant
    self.notes = notes
    self.createdAt = Date()
  }
}

enum PaymentMethod: String, Codable, CaseIterable {
  case cash
  case card

  var displayName: String {
    switch self {
    case .cash: return Localization.string(.expenseCash)
    case .card: return Localization.string(.expenseCard)
    }
  }

  var icon: String {
    switch self {
    case .cash: return "banknote"
    case .card: return "creditcard"
    }
  }
}
