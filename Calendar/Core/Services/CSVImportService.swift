import Foundation
import SwiftData

/// Service for importing CSV files and managing import sessions
class CSVImportService {
  
  private let patternDetection = PatternDetectionService()
  
  /// Import CSV file and return result
  func importCSV(
    csvData: Data,
    fileName: String,
    existingExpenses: [Expense],
    context: ModelContext
  ) -> CSVImportResult {
    
    // Create import session
    let session = CSVImportSession(fileName: fileName)
    
    do {
      // Parse CSV
      guard let csvString = String(data: csvData, encoding: .utf8) else {
        return CSVImportResult(
          session: session,
          transactions: [],
          duplicates: [],
          suggestions: [],
          success: false,
          error: ImportError.invalidEncoding
        )
      }
      
      let allTransactions = CSVParser.parse(csvString: csvString)
      session.transactionCount = allTransactions.count
      
      // Filter out duplicates
      let (uniqueTransactions, duplicates) = filterDuplicates(
        transactions: allTransactions,
        existingExpenses: existingExpenses
      )
      session.duplicateCount = duplicates.count
      
      // Detect patterns
      let suggestions = patternDetection.detectPatterns(from: uniqueTransactions)
      session.templatesSuggested = suggestions.count
      
      // Save session
      context.insert(session)
      
      // Cleanup old sessions
      cleanupOldSessions(context: context)
      
      return CSVImportResult(
        session: session,
        transactions: uniqueTransactions,
        duplicates: duplicates,
        suggestions: suggestions,
        success: true,
        error: nil
      )
      
    } catch {
      return CSVImportResult(
        session: session,
        transactions: [],
        duplicates: [],
        suggestions: [],
        success: false,
        error: error
      )
    }
  }
  
  /// Filter out transactions that are duplicates of existing expenses
  private func filterDuplicates(
    transactions: [CSVTransaction],
    existingExpenses: [Expense]
  ) -> (unique: [CSVTransaction], duplicates: [CSVTransaction]) {
    var unique: [CSVTransaction] = []
    var duplicates: [CSVTransaction] = []
    
    for transaction in transactions {
      if patternDetection.isDuplicate(transaction, existingExpenses: existingExpenses) {
        duplicates.append(transaction)
      } else {
        unique.append(transaction)
      }
    }
    
    return (unique, duplicates)
  }
  
  /// Create templates from suggestions
  func createTemplates(
    from suggestions: [TemplateSuggestion],
    context: ModelContext
  ) -> [RecurringExpenseTemplate] {
    var createdTemplates: [RecurringExpenseTemplate] = []
    
    for suggestion in suggestions {
      let template = RecurringExpenseTemplate(
        title: suggestion.merchant,
        amount: suggestion.suggestedAmount,
        amountTolerance: 0.05,
        categories: suggestion.categories,
        paymentMethod: .card, // Default
        currency: .uah,
        merchant: suggestion.merchant,
        notes: nil,
        frequency: suggestion.frequency,
        startDate: suggestion.occurrences.first ?? Date(),
        occurrenceCount: suggestion.occurrenceCount
      )
      
      context.insert(template)
      createdTemplates.append(template)
    }
    
    return createdTemplates
  }
  
  /// Create a single expense from a transaction
  func createExpense(
    from transaction: CSVTransaction,
    template: RecurringExpenseTemplate? = nil,
    context: ModelContext
  ) -> Expense {
    let categories = template?.allCategories ?? [.other]
    
    let expense = Expense(
      title: transaction.merchant,
      amount: transaction.absoluteAmount,
      date: transaction.date,
      categories: categories,
      paymentMethod: template?.paymentMethodEnum ?? .card,
      currency: transaction.currency,
      merchant: transaction.merchant,
      notes: nil,
      templateId: template?.id,
      isGenerated: false
    )
    
    context.insert(expense)
    return expense
  }
  
  /// Cleanup old import sessions (keep only last 2, delete after 30 days)
  private func cleanupOldSessions(context: ModelContext) {
    let descriptor = FetchDescriptor<CSVImportSession>(
      predicate: #Predicate { $0.isDeleted == false }
    )
    
    do {
      let sessions = try context.fetch(descriptor)
      
      // Sort by date (oldest first)
      let sortedSessions = sessions.sorted { $0.importDate < $1.importDate }
      
      // Keep only last 2, mark others as deleted
      if sortedSessions.count > 2 {
        let toDelete = sortedSessions.dropLast(2)
        for session in toDelete {
          session.isDeleted = true
        }
      }
      
      // Hard delete anything older than 30 days
      let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
      for session in sessions {
        if session.importDate < cutoffDate {
          context.delete(session)
        }
      }
      
      try context.save()
      
    } catch {
      print("Error cleaning up import sessions: \(error)")
    }
  }
  
  /// Get import history
  func getImportHistory(context: ModelContext) -> [CSVImportSession] {
    let descriptor = FetchDescriptor<CSVImportSession>(
      predicate: #Predicate { $0.isDeleted == false },
      sortBy: [SortDescriptor(\.importDate, order: .reverse)]
    )
    
    do {
      return try context.fetch(descriptor)
    } catch {
      return []
    }
  }
}

enum ImportError: LocalizedError {
  case invalidEncoding
  case parseError
  
  var errorDescription: String? {
    switch self {
    case .invalidEncoding:
      return "Invalid file encoding. Please ensure the file is UTF-8 encoded."
    case .parseError:
      return "Unable to parse CSV file. Please check the file format."
    }
  }
}
