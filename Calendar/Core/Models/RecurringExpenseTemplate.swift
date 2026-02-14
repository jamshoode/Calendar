import Foundation
import SwiftData

@Model
class RecurringExpenseTemplate {
  var id: UUID
  var title: String
  var amount: Double
  var amountTolerance: Double  // Variance allowed (default 0.05 = 5%)
  var categories: [String]     // Array of ExpenseCategory rawValues
  var paymentMethod: String
  var currency: String
  var merchant: String         // For fuzzy matching
  var notes: String?
  var frequency: ExpenseFrequency
  var startDate: Date
  var lastGeneratedDate: Date?
  var isActive: Bool
  var isPaused: Bool
  var pausedUntil: Date?       // For temporary pause
  var occurrenceCount: Int     // How many times detected/occurred
  var createdAt: Date
  var updatedAt: Date
  
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
  
  var frequencyEnum: ExpenseFrequency {
    get { ExpenseFrequency(rawValue: frequency.rawValue) ?? .monthly }
    set { frequency = newValue }
  }
  
  /// Check if amount is within tolerance
  func isAmountMatching(_ otherAmount: Double) -> Bool {
    let lowerBound = amount * (1 - amountTolerance)
    let upperBound = amount * (1 + amountTolerance)
    return otherAmount >= lowerBound && otherAmount <= upperBound
  }
  
  /// Calculate next due date
  func nextDueDate(from date: Date? = nil) -> Date? {
    let baseDate = date ?? lastGeneratedDate ?? startDate
    guard frequency != .oneTime else { return nil }
    return frequency.nextDate(from: baseDate)
  }
  
  /// Check if template is currently paused
  var isCurrentlyPaused: Bool {
    if isPaused {
      if let pausedUntil = pausedUntil {
        return Date() < pausedUntil
      }
      return true // Indefinite pause
    }
    return false
  }
  
  init(
    title: String,
    amount: Double,
    amountTolerance: Double = 0.05,
    categories: [ExpenseCategory] = [.other],
    paymentMethod: PaymentMethod = .card,
    currency: Currency = .uah,
    merchant: String,
    notes: String? = nil,
    frequency: ExpenseFrequency = .monthly,
    startDate: Date = Date(),
    occurrenceCount: Int = 1
  ) {
    self.id = UUID()
    self.title = title
    self.amount = amount
    self.amountTolerance = amountTolerance
    self.categories = categories.map { $0.rawValue }
    self.paymentMethod = paymentMethod.rawValue
    self.currency = currency.rawValue
    self.merchant = merchant
    self.notes = notes
    self.frequency = frequency
    self.startDate = startDate
    self.lastGeneratedDate = nil
    self.isActive = true
    self.isPaused = false
    self.pausedUntil = nil
    self.occurrenceCount = occurrenceCount
    self.createdAt = Date()
    self.updatedAt = Date()
  }
}

/// Represents a detected pattern from CSV import
struct TemplateSuggestion: Identifiable {
  let id = UUID()
  let merchant: String
  let amount: Double
  let frequency: ExpenseFrequency
  let occurrences: [Date]
  let categories: [ExpenseCategory]
  let suggestedAmount: Double  // Average of all occurrences
  let confidence: Double       // 0.0 to 1.0 based on pattern regularity
  
  var occurrenceCount: Int {
    occurrences.count
  }
}
