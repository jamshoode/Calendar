import SwiftUI
import SwiftData

struct BudgetView: View {
  let templates: [RecurringExpenseTemplate]
  let expenses: [Expense]
  let viewModel: ExpenseViewModel
  
  @Environment(\.modelContext) private var modelContext
  @State private var editingTemplate: RecurringExpenseTemplate?
  
  private var activeTemplates: [RecurringExpenseTemplate] {
    templates.filter { $0.isActive && !$0.isCurrentlyPaused }
  }
  
  private var pausedTemplates: [RecurringExpenseTemplate] {
    templates.filter { $0.isCurrentlyPaused }
  }
  
  private var monthlyTotal: Double {
    activeTemplates
      .filter { $0.frequency == .monthly || $0.frequency == .yearly }
      .reduce(0) { total, template in
        if template.frequency == .yearly {
          return total + (template.amount / 12)
        }
        return total + template.amount
      }
  }
  
  private var weeklyTotal: Double {
    activeTemplates
      .filter { $0.frequency == .weekly }
      .reduce(0) { $0 + $1.amount }
  }
  
  private var yearlyTotal: Double {
    activeTemplates.reduce(0) { total, template in
      switch template.frequency {
      case .weekly:
        return total + (template.amount * 52)
      case .monthly:
        return total + (template.amount * 12)
      case .yearly:
        return total + template.amount
      default:
        return total
      }
    }
  }
  
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Summary Cards
        HStack(spacing: 12) {
          BudgetSummaryCard(
            title: Localization.string(.expensePeriodMonthly),
            amount: monthlyTotal,
            icon: "calendar",
            color: .blue
          )
          
          BudgetSummaryCard(
            title: Localization.string(.expensePeriodWeekly),
            amount: weeklyTotal,
            icon: "arrow.2.circlepath",
            color: .green
          )
        }
        
        BudgetSummaryCard(
          title: Localization.string(.yearlyProjection),
          amount: yearlyTotal,
          icon: "chart.line.uptrend.xyaxis",
          color: .purple
        )
        
        // Active Templates
        if !activeTemplates.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text(Localization.string(.activeRecurringX(activeTemplates.count)))
                .font(.headline)
              
              Spacer()
              
              Button {
                generateMissingExpenses()
              } label: {
                Image(systemName: "arrow.clockwise")
                  .foregroundColor(.accentColor)
              }
            }
            
            ForEach(activeTemplates) { template in
              TemplateRow(
                template: template,
                onPause: { pauseTemplate(template) },
                onEdit: { editTemplate(template) },
                onDelete: { deleteTemplate(template) }
              )
            }
          }
        }
        
        // Paused Templates
        if !pausedTemplates.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string(.pausedX(pausedTemplates.count)))
              .font(.headline)
              .foregroundColor(.secondary)
            
            ForEach(pausedTemplates) { template in
              TemplateRow(
                template: template,
                onResume: { resumeTemplate(template) },
                onEdit: { editTemplate(template) },
                onDelete: { deleteTemplate(template) }
              )
              .opacity(0.6)
            }
          }
        }
        
        if templates.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "repeat")
              .font(.system(size: 48))
              .foregroundColor(.secondary)
            
            Text(Localization.string(.expenseNoRecurringExpenses))
              .font(.headline)
            
            Text(Localization.string(.uploadCSV))
              .font(.caption)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding(.top, 60)
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 120)
    }
    .sheet(item: $editingTemplate) { template in
      EditTemplateSheet(template: template)
    }
  }

  private func pauseTemplate(_ template: RecurringExpenseTemplate) {
    template.isPaused = true
    template.pausedUntil = nil
    try? modelContext.save()
  }
  
  private func resumeTemplate(_ template: RecurringExpenseTemplate) {
    template.isPaused = false
    template.pausedUntil = nil
    try? modelContext.save()
  }
  
  private func editTemplate(_ template: RecurringExpenseTemplate) {
    editingTemplate = template
  }
  
  private func deleteTemplate(_ template: RecurringExpenseTemplate) {
    // Ask user if they want to keep history
    modelContext.delete(template)
    try? modelContext.save()
  }
  
  private func generateMissingExpenses() {
    RecurringExpenseService.shared.generateRecurringExpenses(context: modelContext)
  }
}

struct BudgetSummaryCard: View {
  let title: String
  let amount: Double
  let icon: String
  let color: Color
  
  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(color)
        Spacer()
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text("\(Currency.uah.symbol)\(String(format: "%.0f", amount))")
          .font(.title2.bold())
          .foregroundColor(.primary)
        
        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }
}

struct TemplateRow: View {
  let template: RecurringExpenseTemplate
  var onPause: (() -> Void)?
  var onResume: (() -> Void)?
  var onEdit: (() -> Void)?
  var onDelete: (() -> Void)?
  
  var body: some View {
    HStack(spacing: 12) {
      // Icon
      ZStack {
        Circle()
          .fill(template.primaryCategory.color.opacity(0.2))
          .frame(width: 40, height: 40)
        
        Image(systemName: template.primaryCategory.icon)
          .foregroundColor(template.primaryCategory.color)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text(template.title)
          .font(.subheadline.bold())
        
        HStack(spacing: 6) {
          Text("\(template.currencyEnum.symbol)\(String(format: "%.2f", template.amount))")
            .font(.caption)
            .foregroundColor(.secondary)
          
          Text("•")
            .font(.caption)
            .foregroundColor(.secondary)
          
          Text(template.frequency.displayName)
            .font(.caption)
            .foregroundColor(.secondary)
          
          if let nextDate = template.nextDueDate() {
            Text("•")
              .font(.caption)
              .foregroundColor(.secondary)
            
            Text(Localization.string(.nextOccurrence(formatDate(nextDate))))
              .font(.caption)
              .foregroundColor(.accentColor)
          }
        }
      }
      
      Spacer()
      
      // Actions
      Menu {
        if onPause != nil {
          Button(action: onPause!) {
            Label(Localization.string(.pause), systemImage: "pause.circle")
          }
        }
        
        if onResume != nil {
          Button(action: onResume!) {
            Label(Localization.string(.resume), systemImage: "play.circle")
          }
        }
        
        if onEdit != nil {
          Button(action: onEdit!) {
            Label(Localization.string(.edit), systemImage: "pencil")
          }
        }
        
        if onDelete != nil {
          Button(role: .destructive, action: onDelete!) {
            Label(Localization.string(.delete), systemImage: "trash")
          }
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM"
    return formatter.string(from: date)
  }
}

#Preview {
  BudgetView(
    templates: [],
    expenses: [],
    viewModel: ExpenseViewModel()
  )
}
