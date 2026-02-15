import Foundation
import SwiftData

/// Service for detecting recurring expense patterns from transactions
class PatternDetectionService {
  
  /// Minimum number of occurrences to suggest a template (reduced to catch more patterns)
  private let minOccurrences = 2
  
  /// Time window for detection (3 months in seconds)
  private let detectionWindow: TimeInterval = 3 * 30 * 24 * 60 * 60
  
  /// Amount variance tolerance (increased to 10% for variable subscriptions)
  private let amountTolerance = 0.10
  
  /// Detect recurring patterns from transactions
  func detectPatterns(from transactions: [CSVTransaction]) -> [TemplateSuggestion] {
    // Filter to last 3 months
    let cutoffDate = Date().addingTimeInterval(-detectionWindow)
    let recentTransactions = transactions.filter { $0.date >= cutoffDate }
    
    // Group by normalized merchant name
    let grouped = Dictionary(grouping: recentTransactions) { normalizeMerchant($0.merchant) }
    
    var suggestions: [TemplateSuggestion] = []
    
    for (normalizedMerchant, merchantTransactions) in grouped {
      // Filter to expenses only (negative amounts)
      let expenses = merchantTransactions.filter { $0.isExpense }
      guard expenses.count >= minOccurrences else { continue }
      
      // Check if this looks like a subscription by keywords
      let isSubscription = isSubscriptionMerchant(normalizedMerchant)
      
      // For subscriptions, be more lenient with amount variance
      let tolerance = isSubscription ? 0.15 : amountTolerance
      
      // Group by similar amounts (within tolerance)
      let amountGroups = groupByAmount(expenses, tolerance: tolerance)
      
      for amountGroup in amountGroups {
        // For subscriptions, allow 2+ occurrences
        let requiredOccurrences = isSubscription ? 2 : minOccurrences
        guard amountGroup.count >= requiredOccurrences else { continue }
        
        // Sort by date
        let sorted = amountGroup.sorted { $0.date < $1.date }
        
        // Detect frequency (more lenient for subscriptions)
        guard let frequency = detectFrequency(from: sorted, isSubscription: isSubscription) else { continue }
        
        // Calculate average amount and confidence
        let amounts = sorted.map { abs($0.amount) }
        let avgAmount = amounts.reduce(0, +) / Double(amounts.count)
        let confidence = calculateConfidence(dates: sorted.map { $0.date }, frequency: frequency, isSubscription: isSubscription)
        
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
  
  /// Check if merchant looks like a subscription service
  private func isSubscriptionMerchant(_ merchant: String) -> Bool {
    let subscriptionKeywords = [
      "netflix", "spotify", "apple", "google", "youtube", "microsoft", 
      "adobe", "amazon", "prime", "disney", "hbo", "paramount", 
      "subscription", "membership", "premium", "plus", "pro",
      "icloud", "dropbox", "zoom", "slack", "notion", "figma",
      "chatgpt", "openai", "midjourney", "canva", "grammarly",
      "підписка", "абонемент", "premium"
    ]
    
    let merchantLower = merchant.lowercased()
    return subscriptionKeywords.contains { merchantLower.contains($0) }
  }
  
  /// Normalize merchant name for matching (less aggressive)
  func normalizeMerchant(_ merchant: String) -> String {
    var normalized = merchant.lowercased()
    
    // Remove transaction IDs and numbers (common in bank statements)
    // But keep numbers that might be part of the name
    normalized = normalized.replacingOccurrences(of: "#\\d+", with: "", options: .regularExpression)
    normalized = normalized.replacingOccurrences(of: "\\b\\d{4,}\\b", with: "", options: .regularExpression)
    
    // Remove common location suffixes
    let locationWords = ["київ", "kyiv", "lviv", "odesa", "kharkiv", "dnipro", "vinnytsia", "ukraine"]
    for word in locationWords {
      normalized = normalized.replacingOccurrences(of: word, with: "")
    }
    
    // Trim whitespace and clean up
    normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    
    return normalized
  }
  
  /// Group transactions by similar amounts
  private func groupByAmount(_ transactions: [CSVTransaction], tolerance: Double) -> [[CSVTransaction]] {
    var groups: [[CSVTransaction]] = []
    var used = Set<UUID>()
    
    for transaction in transactions {
      guard !used.contains(transaction.id) else { continue }
      
      var group = [transaction]
      used.insert(transaction.id)
      
      let baseAmount = abs(transaction.amount)
      let amountTolerance = baseAmount * tolerance
      
      for other in transactions {
        guard !used.contains(other.id) else { continue }
        
        let otherAmount = abs(other.amount)
        if abs(baseAmount - otherAmount) <= amountTolerance {
          group.append(other)
          used.insert(other.id)
        }
      }
      
      groups.append(group)
    }
    
    return groups
  }
  
  /// Detect frequency from sorted dates (more flexible ranges)
  private func detectFrequency(from transactions: [CSVTransaction], isSubscription: Bool) -> ExpenseFrequency? {
    guard transactions.count >= 2 else { return nil }
    
    let dates = transactions.map { $0.date }
    var intervals: [TimeInterval] = []
    
    for i in 1..<dates.count {
      let interval = dates[i].timeIntervalSince(dates[i-1])
      intervals.append(interval)
    }
    
    guard !intervals.isEmpty else { return nil }
    
    let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
    let days = avgInterval / (24 * 60 * 60)
    
    // More flexible ranges for subscriptions
    let weeklyRange = isSubscription ? (5.0...10.0) : (6.0...8.0)
    let monthlyRange = isSubscription ? (25.0...35.0) : (28.0...32.0)
    let yearlyRange = isSubscription ? (350.0...380.0) : (360.0...370.0)
    
    if weeklyRange.contains(days) {
      return .weekly
    } else if monthlyRange.contains(days) {
      return .monthly
    } else if yearlyRange.contains(days) {
      return .yearly
    }
    
    return nil
  }
  
  /// Calculate confidence score based on regularity
  private func calculateConfidence(dates: [Date], frequency: ExpenseFrequency, isSubscription: Bool) -> Double {
    guard dates.count >= 2 else { return 0.0 }
    
    let expectedInterval = Double(frequency.daysInterval) * 24 * 60 * 60
    var totalVariance: TimeInterval = 0
    
    for i in 1..<dates.count {
      let actualInterval = dates[i].timeIntervalSince(dates[i-1])
      let variance = abs(actualInterval - expectedInterval) / expectedInterval
      totalVariance += variance
    }
    
    let avgVariance = totalVariance / Double(dates.count - 1)
    
    // Subscriptions get a confidence boost
    let baseConfidence = max(0, 1 - avgVariance)
    let confidence = isSubscription ? min(1.0, baseConfidence + 0.1) : baseConfidence
    
    return min(1.0, confidence)
  }
  
  /// Suggest categories based on merchant name (expanded keywords)
  private func suggestCategories(for merchant: String) -> [ExpenseCategory] {
    let merchantLower = merchant.lowercased()
    
    // Expanded keyword mapping
    let keywords: [(keywords: [String], category: ExpenseCategory)] = [
      (["пекарня", "булочна", "хліб", "coffee", "starbucks", "cafe", "ресторан", "кафе"], .dining),
      (["сільпо", "атб", "варус", "маркет", "groceries", "supermarket", "silpo", "atb"], .groceries),
      (["заправка", "wog", "окко", "автодор", "shell", "bp", "fuel", "gas"], .transportation),
      (["аптека", "pharmacy", "medical", "лікарня", "hospital", "drugstore"], .healthcare),
      (["кіно", "theatre", "theater", "concert", "entertainment", "movie", "cinema"], .entertainment),
      (["netflix", "spotify", "apple", "google", "subscription", "youtube", "disney", "hbo", "prime", "icloud"], .subscriptions),
      (["зал", "gym", "fitness", "sport"], .healthcare),
      (["одяг", "clothes", "fashion", "zara", "h&m", "shopping"], .shopping),
      (["рент", "rent", "комунальні", "utilities", "комуналка"], .housing),
      (["таксі", "taxi", "uber", "bolt", "унік"], .transportation),
      (["monobank", "поповнення", "переказ"], .other)
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
      
      // Check amount (within 10% tolerance for variable amounts)
      let tolerance = transactionAmount * 0.10
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
