import Foundation
import SwiftData

/// Service for detecting recurring expense patterns from transactions
class PatternDetectionService {
  
  /// Minimum number of occurrences to suggest a template
  private let minOccurrences = 3
  
  /// Time window for detection (3 months in seconds)
  private let detectionWindow: TimeInterval = 3 * 30 * 24 * 60 * 60
  
  /// Amount variance tolerance (5%)
  private let amountTolerance = 0.05
  
  /// Detect recurring patterns from transactions
  func detectPatterns(from transactions: [CSVTransaction]) -> [TemplateSuggestion] {
    // Filter to last 6 months
    let cutoffDate = Date().addingTimeInterval(-detectionWindow)
    let recentTransactions = transactions.filter { $0.date >= cutoffDate }
    
    // Group by normalized merchant name
    let grouped = Dictionary(grouping: recentTransactions) { normalizeMerchant($0.merchant) }
    
    var suggestions: [TemplateSuggestion] = []
    
    for (normalizedMerchant, merchantTransactions) in grouped {
      // Filter to expenses only (negative amounts)
      let expenses = merchantTransactions.filter { $0.isExpense }
      guard expenses.count >= minOccurrences else { continue }
      
      // Group by similar amounts (within tolerance)
      let amountGroups = groupByAmount(expenses)
      
      for amountGroup in amountGroups {
        guard amountGroup.count >= minOccurrences else { continue }
        
        // Sort by date
        let sorted = amountGroup.sorted { $0.date < $1.date }
        
        // Detect frequency
        guard let frequency = detectFrequency(from: sorted) else { continue }
        
        // Calculate average amount and confidence
        let amounts = sorted.map { abs($0.amount) }
        let avgAmount = amounts.reduce(0, +) / Double(amounts.count)
        let confidence = calculateConfidence(dates: sorted.map { $0.date }, frequency: frequency)
        
        // Suggest categories based on merchant name
        let categories = suggestCategories(for: normalizedMerchant)
        
        let suggestion = TemplateSuggestion(
          merchant: normalizedMerchant,
          amount: avgAmount,
          frequency: frequency,
          occurrences: sorted.map { $0.date },
          categories: categories,
          suggestedAmount: avgAmount,
          confidence: confidence
        )
        
        suggestions.append(suggestion)
      }
    }
    
    // Sort by confidence (highest first)
    return suggestions.sorted { $0.confidence > $1.confidence }
  }
  
  /// Normalize merchant name for matching
  private func normalizeMerchant(_ merchant: String) -> String {
    var normalized = merchant.lowercased()
    
    // Remove numbers and special characters
    normalized = normalized.components(separatedBy: CharacterSet.decimalDigits).joined()
    normalized = normalized.components(separatedBy: CharacterSet.punctuationCharacters).joined()
    
    // Remove common location suffixes
    let locationWords = ["київ", "lviv", "odesa", "kharkiv", "dnipro", "vinnytsia"]
    for word in locationWords {
      normalized = normalized.replacingOccurrences(of: word, with: "")
    }
    
    // Trim whitespace
    normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    
    return normalized
  }
  
  /// Group transactions by similar amounts
  private func groupByAmount(_ transactions: [CSVTransaction]) -> [[CSVTransaction]] {
    var groups: [[CSVTransaction]] = []
    var used = Set<UUID>()
    
    for transaction in transactions {
      guard !used.contains(transaction.id) else { continue }
      
      var group = [transaction]
      used.insert(transaction.id)
      
      let baseAmount = abs(transaction.amount)
      let tolerance = baseAmount * amountTolerance
      
      for other in transactions {
        guard !used.contains(other.id) else { continue }
        
        let otherAmount = abs(other.amount)
        if abs(baseAmount - otherAmount) <= tolerance {
          group.append(other)
          used.insert(other.id)
        }
      }
      
      groups.append(group)
    }
    
    return groups
  }
  
  /// Detect frequency from sorted dates
  private func detectFrequency(from transactions: [CSVTransaction]) -> ExpenseFrequency? {
    guard transactions.count >= 3 else { return nil }
    
    let dates = transactions.map { $0.date }
    var intervals: [TimeInterval] = []
    
    for i in 1..<dates.count {
      let interval = dates[i].timeIntervalSince(dates[i-1])
      intervals.append(interval)
    }
    
    guard !intervals.isEmpty else { return nil }
    
    let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
    let days = avgInterval / (24 * 60 * 60)
    
    // Determine frequency based on average interval
    // Weekly: 6-8 days
    // Monthly: 28-32 days
    // Yearly: 360-370 days
    
    if days >= 6 && days <= 8 {
      return .weekly
    } else if days >= 28 && days <= 32 {
      return .monthly
    } else if days >= 360 && days <= 370 {
      return .yearly
    }
    
    return nil
  }
  
  /// Calculate confidence score based on regularity
  private func calculateConfidence(dates: [Date], frequency: ExpenseFrequency) -> Double {
    guard dates.count >= 3 else { return 0.0 }
    
    let expectedInterval = Double(frequency.daysInterval) * 24 * 60 * 60
    var totalVariance: TimeInterval = 0
    
    for i in 1..<dates.count {
      let actualInterval = dates[i].timeIntervalSince(dates[i-1])
      let variance = abs(actualInterval - expectedInterval) / expectedInterval
      totalVariance += variance
    }
    
    let avgVariance = totalVariance / Double(dates.count - 1)
    let confidence = max(0, 1 - avgVariance)
    
    return min(1.0, confidence)
  }
  
  /// Suggest categories based on merchant name
  private func suggestCategories(for merchant: String) -> [ExpenseCategory] {
    let merchantLower = merchant.lowercased()
    
    // Keyword mapping
    let keywords: [(keywords: [String], category: ExpenseCategory)] = [
      (["пекарня", "булочна", "хліб", "coffee", "starbucks", "coffee"], .dining),
      (["сільпо", "атб", "варус", "маркет", "groceries", "supermarket"], .groceries),
      (["заправка", "wog", "окко", "автодор", "shell", "bp"], .transportation),
      (["аптека", "pharmacy", "medical", "лікарня"], .healthcare),
      (["кіно", "theatre", "theater", "concert", "entertainment"], .entertainment),
      (["netflix", "spotify", "apple", "google", "subscription"], .subscriptions),
      (["зал", "gym", "fitness", "sport"], .healthcare),
      (["одяг", "clothes", "fashion", "zara", "h&m"], .shopping),
      (["рент", "rent", "комунальні", "utilities"], .housing)
    ]
    
    for (words, category) in keywords {
      for word in words {
        if merchantLower.contains(word) {
          return [category]
        }
      }
    }
    
    return [.other]
  }
  
  /// Check if transaction is a duplicate of existing expense
  func isDuplicate(_ transaction: CSVTransaction, existingExpenses: [Expense]) -> Bool {
    let normalizedMerchant = normalizeMerchant(transaction.merchant)
    let transactionAmount = abs(transaction.amount)
    
    for expense in existingExpenses {
      // Check same day
      guard Calendar.current.isDate(transaction.date, inSameDayAs: expense.date) else {
        continue
      }
      
      // Check amount (within small tolerance)
      let tolerance = transactionAmount * 0.01 // 1% tolerance
      guard abs(transactionAmount - expense.amount) <= tolerance else {
        continue
      }
      
      // Check merchant (fuzzy match)
      let expenseMerchant = normalizeMerchant(expense.title)
      guard normalizedMerchant == expenseMerchant else {
        continue
      }
      
      return true
    }
    
    return false
  }
}
