import SwiftData
import SwiftUI

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
      category: category,
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
    expense.categoryEnum = category
    expense.paymentMethodEnum = paymentMethod
    expense.currencyEnum = currency
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

  func totalByCategory(expenses: [Expense]) -> [(category: ExpenseCategory, total: Double)] {
    var map: [ExpenseCategory: Double] = [:]
    for expense in expenses {
      map[expense.categoryEnum, default: 0] += expense.amount
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
}
