import Foundation
import SwiftData
import UserNotifications

/// Service for managing recurring expense generation and notifications
class RecurringExpenseService {
  
  static let shared = RecurringExpenseService()
  
  private init() {
    requestNotificationPermissions()
  }
  
  // MARK: - Expense Generation
  
  /// Generate recurring expenses from templates
  /// Call this on app launch and when viewing Budget tab
  func generateRecurringExpenses(context: ModelContext) {
    let descriptor = FetchDescriptor<RecurringExpenseTemplate>()
    
    do {
      let templates = try context.fetch(descriptor)
      
      for template in templates {
        guard !template.isCurrentlyPaused else { continue }
        
        let lastDate = template.lastGeneratedDate ?? template.startDate
        var nextDate = template.nextDueDate(from: lastDate)
        
        // Generate up to 1 month ahead
        let oneMonthFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        while let date = nextDate, date <= oneMonthFromNow {
          // Check if expense already exists for this date
          if !expenseExists(for: template, on: date, context: context) {
            createExpense(from: template, on: date, context: context)
          }
          
          // Move to next occurrence
          nextDate = template.nextDueDate(from: date)
        }
        
        // Update last generated date
        template.lastGeneratedDate = Date()
      }
      
      try context.save()
      
      // Schedule notifications for upcoming expenses
      scheduleUpcomingNotifications(context: context)
      
    } catch {
      print("Error generating recurring expenses: \(error)")
    }
  }
  
  /// Check if an expense already exists for a template on a specific date
  private func expenseExists(
    for template: RecurringExpenseTemplate,
    on date: Date,
    context: ModelContext
  ) -> Bool {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    
    // Fetch all expenses and filter in memory (workaround for predicate limitations)
    let descriptor = FetchDescriptor<Expense>()
    
    do {
      let allExpenses = try context.fetch(descriptor)
      let existing = allExpenses.filter { expense in
        expense.templateId == template.id &&
        expense.date >= startOfDay &&
        expense.date < endOfDay
      }
      return !existing.isEmpty
    } catch {
      return false
    }
  }
  
  /// Create an expense from a template
  private func createExpense(
    from template: RecurringExpenseTemplate,
    on date: Date,
    context: ModelContext
  ) {
    let expense = Expense(
      title: template.title,
      amount: template.amount,
      date: date,
      categories: template.allCategories,
      paymentMethod: template.paymentMethodEnum,
      currency: template.currencyEnum,
      merchant: template.merchant,
      notes: template.notes,
      templateId: template.id,
      isGenerated: true
    )
    
    context.insert(expense)
  }
  
  // MARK: - Notifications
  
  /// Request notification permissions
  private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      }
    }
  }
  
  /// Schedule notifications for upcoming recurring expenses
  func scheduleUpcomingNotifications(context: ModelContext) {
    // Cancel existing notifications
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    
    // Get upcoming expenses (next 7 days)
    let descriptor = FetchDescriptor<RecurringExpenseTemplate>()
    
    do {
      let allTemplates = try context.fetch(descriptor)
      let templates = allTemplates.filter { $0.isActive && !$0.isPaused }
      let upcomingExpenses = getUpcomingExpenses(from: templates, within: 7)
      
      guard !upcomingExpenses.isEmpty else { return }
      
      // Group by date
      let groupedByDate = Dictionary(grouping: upcomingExpenses) { expense in
        Calendar.current.startOfDay(for: expense.date)
      }
      
      // Schedule notification for each date
      for (date, expenses) in groupedByDate.sorted(by: { $0.key < $1.key }) {
        scheduleNotification(for: expenses, on: date)
      }
      
    } catch {
      print("Error scheduling notifications: \(error)")
    }
  }
  
  /// Get upcoming expenses within specified days
  private func getUpcomingExpenses(
    from templates: [RecurringExpenseTemplate],
    within days: Int
  ) -> [(template: RecurringExpenseTemplate, date: Date)] {
    let calendar = Calendar.current
    let now = Date()
    let cutoff = calendar.date(byAdding: .day, value: days, to: now)!
    
    var upcoming: [(RecurringExpenseTemplate, Date)] = []
    
    for template in templates {
      guard let nextDate = template.nextDueDate(), nextDate <= cutoff else { continue }
      upcoming.append((template, nextDate))
    }
    
    return upcoming.sorted { $0.date < $1.date }
  }
  
  /// Schedule a notification for expenses on a specific date
  private func scheduleNotification(
    for expenses: [(template: RecurringExpenseTemplate, date: Date)],
    on date: Date
  ) {
    let content = UNMutableNotificationContent()
    
    if expenses.count == 1 {
      let expense = expenses[0]
      content.title = "💰 Upcoming Payment"
      content.body = "\(expense.template.title) - ₴\(String(format: "%.2f", expense.template.amount)) due tomorrow"
    } else {
      let total = expenses.reduce(0) { $0 + $1.template.amount }
      let names = expenses.prefix(3).map { $0.template.title }.joined(separator: ", ")
      let more = expenses.count > 3 ? " and \(expenses.count - 3) more" : ""
      
      content.title = "💰 \(expenses.count) Payments Due Tomorrow"
      content.body = "Total: ₴\(String(format: "%.2f", total)) - \(names)\(more)"
    }
    
    content.sound = .default
    content.badge = 1
    
    // Schedule for 9 AM the day before
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: date)
    components.day! -= 1
    components.hour = 9
    components.minute = 0
    
    guard let triggerDate = calendar.date(from: components),
          triggerDate > Date() else { return }
    
    let trigger = UNCalendarNotificationTrigger(
      dateMatching: components,
      repeats: false
    )
    
    let request = UNNotificationRequest(
      identifier: "recurring-expense-\(date.timeIntervalSince1970)",
      content: content,
      trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error scheduling notification: \(error)")
      }
    }
  }
  
  // MARK: - Missed Payment Detection
  
  /// Check for missed recurring payments (3+ days overdue)
  func checkMissedPayments(context: ModelContext) -> [RecurringExpenseTemplate] {
    let descriptor = FetchDescriptor<RecurringExpenseTemplate>()
    
    do {
      let allTemplates = try context.fetch(descriptor)
      let templates = allTemplates.filter { $0.isActive && !$0.isPaused }
      let threeDaysAgo = Date().addingTimeInterval(-3 * 24 * 60 * 60)
      
      return templates.filter { template in
        guard let nextDate = template.nextDueDate() else { return false }
        return nextDate < threeDaysAgo && !expenseExists(for: template, on: nextDate, context: context)
      }
      
    } catch {
      return []
    }
  }
}
