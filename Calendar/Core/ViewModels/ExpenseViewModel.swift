import SwiftData
import SwiftUI
import WidgetKit

class ExpenseViewModel {

  func addExpense(
    title: String,
    amount: Double,
    date: Date,
    category: ExpenseCategory,
    paymentMethod: PaymentMethod,
    currency: Currency,
    merchant: String?,
    notes: String?,
    context: ModelContext
  ) throws {
    let expense = Expense(
      title: title,
      amount: amount,
      date: date,
      categories: [category],
      paymentMethod: paymentMethod,
      currency: currency,
      merchant: merchant,
      notes: notes
    )
    context.insert(expense)
    try context.save()
  }

  func updateExpense(
    _ expense: Expense,
    title: String,
    amount: Double,
    date: Date,
    category: ExpenseCategory,
    paymentMethod: PaymentMethod,
    currency: Currency,
    merchant: String?,
    notes: String?,
    context: ModelContext
  ) throws {
    expense.title = title
    expense.amount = amount
    expense.date = date
    expense.categories = [category.rawValue]
    expense.paymentMethod = paymentMethod.rawValue
    expense.currency = currency.rawValue
    expense.merchant = merchant
    expense.notes = notes
    try context.save()
  }

  func deleteExpense(_ expense: Expense, context: ModelContext) throws {
    context.delete(expense)
    try context.save()
  }

  // MARK: - Aggregation

  func totalForPeriod(expenses: [Expense], start: Date, end: Date) -> Double {
    expenses
      .filter { $0.date >= start && $0.date <= end }
      .reduce(0) { $0 + $1.amount }
  }

  /// Calculate total amount in UAH for a period (converts all currencies to UAH)
  func totalInUAHForPeriod(expenses: [Expense], start: Date, end: Date) -> Double {
    let filtered = expenses.filter { $0.date >= start && $0.date <= end }
    return filtered.reduce(0) { total, expense in
      total + expense.currencyEnum.convertToUAH(expense.amount)
    }
  }

  /// Get multi-currency totals for a period
  /// Returns: (uah: Double, usd: Double, eur: Double)
  /// - uah: Total in UAH (converted from all currencies)
  /// - usd: Total in USD (converted from UAH total)
  /// - eur: Total in EUR (converted from UAH total)
  func multiCurrencyTotalsForPeriod(expenses: [Expense], start: Date, end: Date) -> (uah: Double, usd: Double, eur: Double) {
    let totalUAH = totalInUAHForPeriod(expenses: expenses, start: start, end: end)
    let usd = Currency.usd.convertFromUAH(totalUAH)
    let eur = Currency.eur.convertFromUAH(totalUAH)
    return (uah: totalUAH, usd: usd, eur: eur)
  }

  func totalByCategory(expenses: [Expense]) -> [(category: ExpenseCategory, total: Double)] {
    var map: [ExpenseCategory: Double] = [:]
    for expense in expenses {
      map[expense.primaryCategory, default: 0] += expense.amount
    }
    return map.sorted { $0.value > $1.value }.map { (category: $0.key, total: $0.value) }
  }

  func dailyTotals(expenses: [Expense]) -> [Date: Double] {
    var map: [Date: Double] = [:]
    let calendar = Calendar.current
    for expense in expenses {
      let day = calendar.startOfDay(for: expense.date)
      map[day, default: 0] += expense.amount
    }
    return map
  }

  func groupedByDate(expenses: [Expense]) -> [(date: Date, expenses: [Expense])] {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
    return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, expenses: $0.value) }
  }
  
  // MARK: - Widget Sync
  
  func syncExpensesToWidget(context: ModelContext) {
    let calendar = Calendar.current
    let now = Date()
    let weekLater = calendar.date(byAdding: .day, value: 7, to: now)!
    
    let descriptor = FetchDescriptor<Expense>(
      predicate: #Predicate { expense in
        expense.date >= now && expense.date <= weekLater
      },
      sortBy: [SortDescriptor(\.date)]
    )
    
    do {
      let expenses = try context.fetch(descriptor)
      let widgetExpenses = expenses.prefix(2).map { expense -> WidgetExpenseItem in
        WidgetExpenseItem(
          id: expense.id.uuidString,
          title: expense.title,
          amount: expense.amount,
          date: expense.date,
          currency: expense.currency,
          category: expense.primaryCategory.rawValue
        )
      }
      
      let defaults = UserDefaults(suiteName: "group.com.shoode.calendar")
      if let encoded = try? JSONEncoder().encode(Array(widgetExpenses)) {
        defaults?.set(encoded, forKey: "widgetUpcomingExpenses")
        defaults?.synchronize()
      }
      WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
    } catch {
      // Silently fail for widget sync
    }
  }
}

// MARK: - Widget Data Models

struct WidgetExpenseItem: Codable {
  let id: String
  let title: String
  let amount: Double
  let date: Date
  let currency: String
  let category: String
}
