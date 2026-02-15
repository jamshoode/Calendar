import Foundation
import SwiftData
import UserNotifications
import os

/// Service for managing recurring expense generation and notifications
class RecurringExpenseService {

  static let shared = RecurringExpenseService()

  private init() {}

  // MARK: - Expense Generation

  /// Generate recurring expenses from templates
  /// Call this on app launch and when viewing Budget tab
  func generateRecurringExpenses(context: ModelContext) {
    let descriptor = FetchDescriptor<RecurringExpenseTemplate>()

    do {
      let templates = try context.fetch(descriptor)

      for template in templates {
        guard !template.isCurrentlyPaused else { continue }
        guard template.frequency != .oneTime else { continue }

        // Generate up to 2 months ahead
        let twoMonthsFromNow = Date().addingTimeInterval(60 * 24 * 60 * 60)
        let calendar = Calendar.current

        // Always step from startDate by adding N periods to preserve day-of-month
        // e.g., startDate = Nov 24 → Dec 24, Jan 24, Feb 24, etc.
        var multiplier = 0
        var lastGeneratedExpenseDate: Date? = nil

        while true {
          let candidateDate: Date?
          switch template.frequency {
          case .weekly:
            candidateDate = calendar.date(
              byAdding: .weekOfYear, value: multiplier, to: template.startDate)
          case .monthly:
            candidateDate = calendar.date(
              byAdding: .month, value: multiplier, to: template.startDate)
          case .yearly:
            candidateDate = calendar.date(
              byAdding: .year, value: multiplier, to: template.startDate)
          case .oneTime:
            candidateDate = nil
          }

          guard let date = candidateDate else { break }

          // Skip the startDate itself (occurrence 0) — only generate future ones
          // But include it if it's today or in the future
          if multiplier == 0 && date < calendar.startOfDay(for: Date()) {
            multiplier += 1
            continue
          }

          // Stop if we've gone past our generation window
          if date > twoMonthsFromNow { break }

          // Create expense if it doesn't exist
          if !expenseExists(for: template, on: date, context: context) {
            createExpense(from: template, on: date, context: context)
          }

          lastGeneratedExpenseDate = date
          multiplier += 1

          // Safety: prevent infinite loops
          if multiplier > 500 { break }
        }

        // Update last generated date, but do NOT move it into the future.
        // Only advance lastGeneratedDate if the last generated expense is today or in the past.
        if let lastExpenseDate = lastGeneratedExpenseDate {
          if lastExpenseDate <= Date() {
            template.lastGeneratedDate = lastExpenseDate
          } else {
            // If we only generated future occurrences, leave lastGeneratedDate unchanged
          }
        }
      }

      try context.save()

      // Schedule notifications for upcoming expenses
      scheduleUpcomingNotifications(context: context)

    } catch {
      Logging.log.error(
        "Error generating recurring expenses: \(String(describing: error), privacy: .public)")
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
        expense.templateId == template.id && expense.date >= startOfDay && expense.date < endOfDay
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
      isGenerated: true,
      isIncome: template.isIncome
    )
    // Record the template's updatedAt as a lightweight snapshot marker
    expense.templateSnapshotHash = "\(template.updatedAt.timeIntervalSince1970)"

    context.insert(expense)
  }

  // MARK: - Notifications

  /// Schedule notifications for upcoming recurring expenses
  func scheduleUpcomingNotifications(context: ModelContext) {
    // Only cancel existing EXPENSE notifications (not alarm/event/todo ones)
    // Capture the ModelContainer so we can create a main-thread ModelContext for scheduling
    let modelContainer = context.container
    UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
      let expenseIds =
        requests
        .filter { $0.identifier.hasPrefix("recurring-expense-") }
        .map { $0.identifier }
      UNUserNotificationCenter.current().removePendingNotificationRequests(
        withIdentifiers: expenseIds)

      // Run scheduling on the main actor using a main-thread ModelContext
      DispatchQueue.main.async {
        // modelContainer is non-optional; create a main-thread ModelContext directly
        let mainContext = ModelContext(modelContainer)
        self?.scheduleNewExpenseNotifications(context: mainContext)
      }
    }
  }

  private func scheduleNewExpenseNotifications(context: ModelContext) {
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
      Logging.log.error(
        "Error scheduling notifications: \(String(describing: error), privacy: .public)")
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

    return upcoming.sorted {
      (item1: (RecurringExpenseTemplate, Date), item2: (RecurringExpenseTemplate, Date)) -> Bool in
      item1.1 < item2.1
    }
  }

  /// Schedule a notification for expenses on a specific date
  private func scheduleNotification(
    for expenses: [(template: RecurringExpenseTemplate, date: Date)],
    on date: Date
  ) {
    let content = UNMutableNotificationContent()

    if expenses.count == 1 {
      let expense = expenses[0]
      let symbol = expense.template.currencyEnum.symbol
      content.title = "💰 Upcoming Payment"
      content.body =
        "\(expense.template.title) - \(symbol)\(String(format: "%.2f", expense.template.amount)) due tomorrow"
    } else {
      let total = expenses.reduce(0) { $0 + $1.template.amount }
      let names = expenses.prefix(3).map { $0.template.title }.joined(separator: ", ")
      let more = expenses.count > 3 ? " and \(expenses.count - 3) more" : ""
      // Use the first expense's currency as the common symbol
      let symbol = expenses.first?.template.currencyEnum.symbol ?? "₴"

      content.title = "💰 \(expenses.count) Payments Due Tomorrow"
      content.body = "Total: \(symbol)\(String(format: "%.2f", total)) - \(names)\(more)"
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
      triggerDate > Date()
    else { return }

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
        Logging.log.error(
          "Error scheduling notification: \(String(describing: error), privacy: .public)")
      }
    }
  }

  // MARK: - Update Generated Expenses (apply template edits)

  private struct _UndoSnapshot: Codable {
    let expenseId: UUID
    let title: String
    let amount: Double
    let merchant: String?
    let notes: String?
    let paymentMethod: String
    let currency: String
    let isIncome: Bool
    // Optional categories: added to support undoing category changes (backwards-compatible)
    let categories: [String]?
    let templateSnapshotHash: String?
  }

  /// Count matching future generated expenses for preview/UI
  func countFutureGeneratedExpenses(
    for template: RecurringExpenseTemplate, from date: Date = Date(), context: ModelContext
  ) -> Int {
    do {
      let all = try context.fetch(FetchDescriptor<Expense>())
      let startOfDay = Calendar.current.startOfDay(for: date)
      return all.filter { $0.templateId == template.id && $0.isGenerated && $0.date >= startOfDay }
        .count
    } catch {
      return 0
    }
  }

  /// Update future generated expenses using values from the template.
  /// Skips any expenses that were manually edited by the user.
  func updateGeneratedExpenses(
    for template: RecurringExpenseTemplate, applyFrom date: Date = Date(), context: ModelContext
  ) -> (updatedCount: Int, skippedManualCount: Int) {
    let startOfDay = Calendar.current.startOfDay(for: date)
    var updated = 0
    var skipped = 0
    var undoSnapshots: [_UndoSnapshot] = []

    do {
      let allExpenses = try context.fetch(FetchDescriptor<Expense>())
      let candidates = allExpenses.filter {
        $0.templateId == template.id && $0.isGenerated && $0.date >= startOfDay
      }

      for expense in candidates {
        if expense.isManuallyEdited {
          skipped += 1
          continue
        }

        // Save a pre-update snapshot for possible undo
        let snap = _UndoSnapshot(
          expenseId: expense.id,
          title: expense.title,
          amount: expense.amount,
          merchant: expense.merchant,
          notes: expense.notes,
          paymentMethod: expense.paymentMethod,
          currency: expense.currency,
          isIncome: expense.isIncome,
          categories: expense.categories,
          templateSnapshotHash: expense.templateSnapshotHash
        )
        undoSnapshots.append(snap)

        // Apply template fields
        expense.title = template.title
        expense.amount = template.amount
        expense.categories = template.allCategories.map { $0.rawValue }
        expense.paymentMethod = template.paymentMethod
        expense.currency = template.currency
        expense.merchant = template.merchant
        expense.notes = template.notes
        expense.isIncome = template.isIncome
        expense.templateSnapshotHash = "\(template.updatedAt.timeIntervalSince1970)"

        updated += 1
      }

      // Persist undo buffer in UserDefaults (short-lived)
      if !undoSnapshots.isEmpty {
        if let data = try? JSONEncoder().encode(undoSnapshots) {
          UserDefaults.standard.set(data, forKey: "lastTemplateUpdate.\(template.id.uuidString)")
        }
      }

      try context.save()

      // Resync widgets & notifications
      ExpenseViewModel().syncExpensesToWidget(context: context)
      scheduleUpcomingNotifications(context: context)

    } catch {
      Logging.log.error(
        "Error updating generated expenses: \(String(describing: error), privacy: .public)")
    }

    return (updated, skipped)
  }

  /// Undo the most recent template-driven update (best-effort)
  func undoLastTemplateUpdate(templateId: UUID, context: ModelContext) -> Bool {
    // Load snapshot (best-effort simple implementation)
    let key = "lastTemplateUpdate.\(templateId.uuidString)"
    guard let data = UserDefaults.standard.data(forKey: key),
      let snaps = try? JSONDecoder().decode([_UndoSnapshot].self, from: data)
    else {
      return false
    }

    var applied = false
    do {
      for snap in snaps {
        if let expense = try context.fetch(FetchDescriptor<Expense>()).first(where: {
          $0.id == snap.expenseId
        }) {
          expense.title = snap.title
          expense.amount = snap.amount
          expense.merchant = snap.merchant
          expense.notes = snap.notes
          // Restore categories if present in snapshot (backwards-compatible)
          if let cats = snap.categories {
            expense.categories = cats
          }
          expense.paymentMethod = snap.paymentMethod
          expense.currency = snap.currency
          expense.isIncome = snap.isIncome
          expense.templateSnapshotHash = snap.templateSnapshotHash
          applied = true
        }
      }
      if applied {
        try context.save()
        ExpenseViewModel().syncExpensesToWidget(context: context)
        scheduleUpcomingNotifications(context: context)
        UserDefaults.standard.removeObject(forKey: key)
      }
    } catch {
      ErrorPresenter.presentOnMain(error)
      Logging.log.error(
        "Failed to undo template update: \(String(describing: error), privacy: .public)")
      return false
    }

    return applied
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
        return nextDate < threeDaysAgo
          && !expenseExists(for: template, on: nextDate, context: context)
      }

    } catch {
      return []
    }
  }
}
