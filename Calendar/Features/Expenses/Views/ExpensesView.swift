import SwiftData
import SwiftUI

struct ExpensesView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Expense.date) private var expenses: [Expense]
  @Query(sort: \RecurringExpenseTemplate.createdAt) private var templates: [RecurringExpenseTemplate]
  
  @State private var selectedSegment: ExpenseSegment = .history
  @State private var selectedPeriod: ExpensePeriod = .monthly
  @State private var showingAddExpense = false
  @State private var editingExpense: Expense? = nil
  @State private var showingCSVImport = false
  @State private var showingClearConfirmation = false
  @State private var showingAddTemplate = false
   
   private let viewModel = ExpenseViewModel()
  
  enum ExpenseSegment: String, CaseIterable {
    case history = "History"
    case budget = "Budget"
    case insights = "Insights"
  }
  
  enum ExpensePeriod: String, CaseIterable {
    case weekly, monthly, yearly
    var displayName: String {
      switch self {
      case .weekly: return "Weekly"
      case .monthly: return "Monthly"
      case .yearly: return "Yearly"
      }
    }
  }
  
  private var filteredExpenses: [Expense] {
    let bounds = periodBounds(for: selectedPeriod)
    return expenses.filter { $0.date >= bounds.start && $0.date <= bounds.end }
  }
  
  private func periodBounds(for period: ExpensePeriod) -> (start: Date, end: Date) {
    let calendar = Calendar.current
    let today = Date()
    let interval: DateInterval
    switch period {
    case .weekly: interval = calendar.dateInterval(of: .weekOfYear, for: today) ?? DateInterval(start: today, end: today)
    case .monthly: interval = calendar.dateInterval(of: .month, for: today) ?? DateInterval(start: today, end: today)
    case .yearly: interval = calendar.dateInterval(of: .year, for: today) ?? DateInterval(start: today, end: today)
    }
    return (interval.start, calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end)
  }
  
  var body: some View {
    VStack(spacing: 0) {
      // Header with Segment Picker
      VStack(spacing: 16) {
        HStack {
          Text("EXPENSES")
            .font(.system(size: 14, weight: .black))
            .tracking(2)
            .foregroundColor(.textSecondary)
          
          Spacer()
          
          HStack(spacing: 16) {
            Button {
              showingAddTemplate = true
            } label: {
              Image(systemName: "plus.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)
            }
            
            Button {
              showingCSVImport = true
            } label: {
              Image(systemName: "arrow.down.doc")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)
            }
            
            Button {
              showingClearConfirmation = true
            } label: {
              Image(systemName: "trash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
            }
          }
        }
        
        // Segment Picker
        HStack(spacing: 0) {
          ForEach(ExpenseSegment.allCases, id: \.self) { segment in
            Button {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSegment = segment
              }
            } label: {
              Text(segment.rawValue)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(selectedSegment == segment ? .white : .textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(selectedSegment == segment ? Color.accentColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
          }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .glassHalo(cornerRadius: 14)
        
        // Period picker (only for History segment)
        if selectedSegment == .history {
          HStack(spacing: 0) {
            ForEach(ExpensePeriod.allCases, id: \.self) { period in
              Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  selectedPeriod = period
                }
              } label: {
                Text(period.displayName)
                  .font(.system(size: 12, weight: .bold))
                  .foregroundColor(selectedPeriod == period ? .white : .textSecondary)
                  .frame(maxWidth: .infinity)
                  .frame(height: 32)
                  .background(selectedPeriod == period ? Color.accentColor.opacity(0.8) : Color.clear)
                  .clipShape(RoundedRectangle(cornerRadius: 8))
              }
              .buttonStyle(.plain)
            }
          }
          .padding(4)
          .background(.ultraThinMaterial.opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 10)
      
      // Content based on selected segment
      Group {
        switch selectedSegment {
        case .history:
          HistoryView(
            expenses: filteredExpenses,
            period: selectedPeriod,
            viewModel: viewModel,
            onEdit: { expense in
              editingExpense = expense
              showingAddExpense = true
            }
          )
        case .budget:
          BudgetView(
            templates: templates,
            expenses: expenses,
            viewModel: viewModel
          )
        case .insights:
          InsightsView(
            expenses: expenses,
            viewModel: viewModel
          )
        }
      }
    }
    .overlay(alignment: .bottomTrailing) {
      Button(action: {
        editingExpense = nil
        showingAddExpense = true
      }) {
        Image(systemName: "plus")
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.white)
          .frame(width: 60, height: 60)
          .background(Color.accentColor)
          .clipShape(Circle())
          .shadow(color: Color.accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
      }
      .padding(.trailing, 24)
      .padding(.bottom, 100)
    }
    .sheet(isPresented: $showingAddExpense) {
      AddExpenseSheet(
        expense: editingExpense,
        onSave: { title, amount, date, category, paymentMethod, currency, merchant, notes in
          do {
            if let expense = editingExpense {
              try viewModel.updateExpense(expense, title: title, amount: amount, date: date, category: category, paymentMethod: paymentMethod, currency: currency, merchant: merchant, notes: notes, context: modelContext)
            } else {
              try viewModel.addExpense(title: title, amount: amount, date: date, category: category, paymentMethod: paymentMethod, currency: currency, merchant: merchant, notes: notes, context: modelContext)
            }
          } catch {
            ErrorPresenter.shared.present(error)
          }
        },
        onDelete: {
          if let expense = editingExpense {
            try? viewModel.deleteExpense(expense, context: modelContext)
          }
        }
      )
    }
    .sheet(isPresented: $showingCSVImport) {
      CSVImportView()
    }
    .sheet(isPresented: $showingAddTemplate) {
      AddTemplateSheet()
    }
    .confirmationDialog(
      "Clear All Data?",
      isPresented: $showingClearConfirmation,
      titleVisibility: .visible
    ) {
      Button("Clear All Expenses", role: .destructive) {
        clearAllExpenses()
      }
      Button("Clear All Templates", role: .destructive) {
        clearAllTemplates()
      }
      Button("Clear Everything", role: .destructive) {
        clearAllExpenses()
        clearAllTemplates()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This action cannot be undone. All your data will be permanently deleted.")
    }
  }
  
  private func clearAllExpenses() {
    for expense in expenses {
      modelContext.delete(expense)
    }
    try? modelContext.save()
  }
  
  private func clearAllTemplates() {
    for template in templates {
      modelContext.delete(template)
    }
    try? modelContext.save()
  }
}

// MARK: - History View

struct HistoryView: View {
  let expenses: [Expense]
  let period: ExpensesView.ExpensePeriod
  let viewModel: ExpenseViewModel
  let onEdit: (Expense) -> Void
  
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Total Amount
        let bounds = periodBounds()
        let multiCurrencyTotals = viewModel.multiCurrencyTotalsForPeriod(expenses: expenses, start: bounds.start, end: bounds.end)
        
        VStack(spacing: 16) {
          VStack(spacing: 4) {
            Text("TOTAL")
              .font(.system(size: 10, weight: .black))
              .foregroundColor(.textTertiary)
              .tracking(2)
            
            Text("₴\(String(format: "%.2f", multiCurrencyTotals.uah))")
              .font(.system(size: 48, weight: .black, design: .rounded))
              .foregroundColor(.textPrimary)
          }
          
          HStack(spacing: 24) {
            VStack(spacing: 2) {
              Text("$")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.textTertiary)
              Text(String(format: "%.2f", multiCurrencyTotals.usd))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.textSecondary)
            }
            
            Divider()
              .frame(height: 24)
            
            VStack(spacing: 2) {
              Text("€")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.textTertiary)
              Text(String(format: "%.2f", multiCurrencyTotals.eur))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.textSecondary)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
          ZStack {
            Circle()
              .fill(Color.accentColor.opacity(0.1))
              .frame(width: 200, height: 200)
              .blur(radius: 50)
          }
        )
        
        if expenses.isEmpty {
          VStack(spacing: 20) {
            Image(systemName: "creditcard")
              .font(.system(size: 48))
              .foregroundColor(.textTertiary)
            Text("No expenses")
              .font(.body)
              .foregroundColor(.textSecondary)
          }
          .padding(.top, 40)
        } else {
          ForEach(viewModel.groupedByDate(expenses: expenses), id: \.date) { group in
            VStack(alignment: .leading, spacing: 12) {
              Text(group.date.formatted(date: .abbreviated, time: .omitted).uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.textTertiary)
                .padding(.leading, 4)
              
              ForEach(group.expenses, id: \.id) { expense in
                ExpenseRow(expense: expense)
                  .onTapGesture {
                    onEdit(expense)
                  }
              }
            }
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 120)
    }
  }
  
  private func periodBounds() -> (start: Date, end: Date) {
    let calendar = Calendar.current
    let today = Date()
    let interval: DateInterval
    switch period {
    case .weekly: interval = calendar.dateInterval(of: .weekOfYear, for: today) ?? DateInterval(start: today, end: today)
    case .monthly: interval = calendar.dateInterval(of: .month, for: today) ?? DateInterval(start: today, end: today)
    case .yearly: interval = calendar.dateInterval(of: .year, for: today) ?? DateInterval(start: today, end: today)
    }
    return (interval.start, calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end)
  }
}

#Preview {
  ExpensesView()
}
