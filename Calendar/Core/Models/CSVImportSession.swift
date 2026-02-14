import Foundation
import SwiftData

@Model
class CSVImportSession {
  var id: UUID
  var importDate: Date
  var fileName: String
  var transactionCount: Int
  var templatesSuggested: Int
  var templatesCreated: Int
  var duplicateCount: Int
  var isDeleted: Bool
  
  /// Date when this session should be hard deleted (30 days after import)
  var deleteAfterDate: Date {
    importDate.addingTimeInterval(30 * 24 * 60 * 60)
  }
  
  /// Check if session is older than 30 days
  var shouldBeDeleted: Bool {
    Date() >= deleteAfterDate
  }
  
  init(
    fileName: String,
    transactionCount: Int = 0,
    templatesSuggested: Int = 0,
    templatesCreated: Int = 0,
    duplicateCount: Int = 0
  ) {
    self.id = UUID()
    self.importDate = Date()
    self.fileName = fileName
    self.transactionCount = transactionCount
    self.templatesSuggested = templatesSuggested
    self.templatesCreated = templatesCreated
    self.duplicateCount = duplicateCount
    self.isDeleted = false
  }
}

/// Represents a single transaction parsed from CSV
struct CSVTransaction: Identifiable {
  let id = UUID()
  let date: Date
  let merchant: String
  let amount: Double  // Negative = expense, Positive = income
  let currency: Currency
  let rawData: [String: String]  // Original row data for reference
  
  var isExpense: Bool {
    amount < 0
  }
  
  var isIncome: Bool {
    amount > 0
  }
  
  /// Returns absolute amount (always positive)
  var absoluteAmount: Double {
    abs(amount)
  }
}

/// Result of CSV import operation
struct CSVImportResult {
  let session: CSVImportSession
  let transactions: [CSVTransaction]
  let duplicates: [CSVTransaction]
  let suggestions: [TemplateSuggestion]
  let success: Bool
  let error: Error?
}
