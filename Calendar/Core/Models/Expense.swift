import Foundation
import SwiftData

@Model
class Expense {
  var id: UUID
  var title: String
  var amount: Double
  var date: Date
  var categories: [String]  // Array of ExpenseCategory rawValues (max 3)
  var paymentMethod: String  // "cash" or "card"
  var currency: String  // currency rawValue (usd/uah/eur)
  var merchant: String?
  var notes: String?
  var createdAt: Date

  // Recurring expense tracking
  var templateId: UUID?  // Links to RecurringTemplate (nil = one-time)
  var isGenerated: Bool  // true = auto-created from template
  var isIncome: Bool = false  // true = income, false = expense

  // Protect user edits made directly to generated expenses
  var isManuallyEdited: Bool = false

  // Snapshot/version marker copied from the template when the expense was generated
  var templateSnapshotHash: String?

  var primaryCategory: ExpenseCategory {
    ExpenseCategory(rawValue: categories.first ?? "other") ?? .other
  }

  var allCategories: [ExpenseCategory] {
    categories.compactMap { ExpenseCategory(rawValue: $0) }
  }

  var paymentMethodEnum: PaymentMethod {
    get { PaymentMethod(rawValue: paymentMethod) ?? .card }
    set { paymentMethod = newValue.rawValue }
  }

  var currencyEnum: Currency {
    get { Currency(rawValue: currency) ?? .uah }
    set { currency = newValue.rawValue }
  }

  /// Add a category (returns false if max 3 reached)
  func addCategory(_ category: ExpenseCategory) -> Bool {
    guard categories.count < 3 else { return false }
    if !categories.contains(category.rawValue) {
      categories.append(category.rawValue)
    }
    return true
  }

  /// Remove a category
  func removeCategory(_ category: ExpenseCategory) {
    categories.removeAll { $0 == category.rawValue }
  }

  init(
    title: String,
    amount: Double,
    date: Date = Date(),
    categories: [ExpenseCategory] = [.other],
    paymentMethod: PaymentMethod = .card,
    currency: Currency = .uah,
    merchant: String? = nil,
    notes: String? = nil,
    templateId: UUID? = nil,
    isGenerated: Bool = false,
    isIncome: Bool = false
  ) {
    self.id = UUID()
    self.title = title
    self.amount = amount
    self.date = date
    self.categories = categories.map { $0.rawValue }
    self.paymentMethod = paymentMethod.rawValue
    self.currency = currency.rawValue
    self.merchant = merchant
    self.notes = notes
    self.createdAt = Date()
    self.templateId = templateId
    self.isGenerated = isGenerated
    self.isIncome = isIncome
  }
}

enum Currency: String, Codable, CaseIterable {
  case usd
  case uah
  case eur

  var symbol: String {
    switch self {
    case .usd: return "$"
    case .uah: return "₴"
    case .eur: return "€"
    }
  }

  var displayName: String {
    switch self {
    case .usd: return "USD"
    case .uah: return "UAH"
    case .eur: return "EUR"
    }
  }

  /// Exchange rate to UAH (1 unit of this currency = X UAH)
  var rateToUAH: Double {
    switch self {
    case .usd: return 43.0
    case .uah: return 1.0
    case .eur: return 51.0
    }
  }

  /// Convert amount from this currency to UAH
  func convertToUAH(_ amount: Double) -> Double {
    return amount * rateToUAH
  }

  /// Convert amount from UAH to this currency
  func convertFromUAH(_ amountInUAH: Double) -> Double {
    return amountInUAH / rateToUAH
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

enum ExpenseFrequency: String, Codable, CaseIterable {
  case oneTime = "oneTime"
  case weekly = "weekly"
  case monthly = "monthly"
  case yearly = "yearly"

  var displayName: String {
    switch self {
    case .oneTime: return Localization.string(.none)
    case .weekly: return Localization.string(.expenseWeekly)
    case .monthly: return Localization.string(.expenseMonthly)
    case .yearly: return Localization.string(.expenseYearly)
    }
  }

  /// Approximate days between occurrences
  var daysInterval: Int {
    switch self {
    case .oneTime: return 0
    case .weekly: return 7
    case .monthly: return 30
    case .yearly: return 365
    }
  }

  /// Get next occurrence date from a given date
  func nextDate(from date: Date) -> Date {
    let calendar = Calendar.current
    switch self {
    case .oneTime:
      return date
    case .weekly:
      return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
    case .monthly:
      return calendar.date(byAdding: .month, value: 1, to: date) ?? date
    case .yearly:
      return calendar.date(byAdding: .year, value: 1, to: date) ?? date
    }
  }
}
