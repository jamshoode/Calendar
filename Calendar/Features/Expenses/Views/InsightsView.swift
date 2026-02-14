import SwiftUI

struct InsightsView: View {
  let expenses: [Expense]
  let viewModel: ExpenseViewModel
  
  private var currentMonthExpenses: [Expense] {
    let calendar = Calendar.current
    let now = Date()
    return expenses.filter {
      calendar.isDate($0.date, equalTo: now, toGranularity: .month)
    }
  }
  
  private var lastMonthExpenses: [Expense] {
    let calendar = Calendar.current
    guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else { return [] }
    return expenses.filter {
      calendar.isDate($0.date, equalTo: lastMonth, toGranularity: .month)
    }
  }
  
  private var categoryBreakdown: [(category: ExpenseCategory, amount: Double, percentage: Double)] {
    let total = currentMonthExpenses.reduce(0) { $0 + $1.amount }
    guard total > 0 else { return [] }
    
    let grouped = Dictionary(grouping: currentMonthExpenses) { $0.primaryCategory }
    return grouped.map { (category, expenses) in
      let amount = expenses.reduce(0) { $0 + $1.amount }
      return (category, amount, (amount / total) * 100)
    }.sorted { $0.amount > $1.amount }
  }
  
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Month-over-month trends
        if !lastMonthExpenses.isEmpty {
          VStack(alignment: .leading, spacing: 16) {
            Text("SPENDING TRENDS")
              .font(.system(size: 12, weight: .black))
              .tracking(1)
              .foregroundColor(.secondary)
            
            let trends = calculateTrends()
            ForEach(trends.prefix(5), id: \.category) { trend in
              TrendRow(trend: trend)
            }
          }
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(12)
        }
        
        // Category breakdown
        if !categoryBreakdown.isEmpty {
          VStack(alignment: .leading, spacing: 16) {
            Text("THIS MONTH'S SPENDING")
              .font(.system(size: 12, weight: .black))
              .tracking(1)
              .foregroundColor(.secondary)
            
            ForEach(categoryBreakdown, id: \.category) { item in
              CategoryBreakdownRow(
                category: item.category,
                amount: item.amount,
                percentage: item.percentage
              )
            }
          }
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(12)
        }
        
        // Income section
        let income = calculateIncome()
        if income > 0 {
          VStack(alignment: .leading, spacing: 16) {
            Text("INCOME THIS MONTH")
              .font(.system(size: 12, weight: .black))
              .tracking(1)
              .foregroundColor(.secondary)
            
            HStack {
              Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
              
              VStack(alignment: .leading) {
                Text("₴\(String(format: "%.2f", income))")
                  .font(.title2.bold())
                
                let totalExpenses = currentMonthExpenses.reduce(0) { $0 + $1.amount }
                let net = income - totalExpenses
                Text("Net: ₴\(String(format: "%.2f", net))")
                  .font(.caption)
                  .foregroundColor(net >= 0 ? .green : .red)
              }
              
              Spacer()
            }
          }
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(12)
        }
        
        if expenses.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "chart.pie")
              .font(.system(size: 48))
              .foregroundColor(.secondary)
            
            Text("No Data Yet")
              .font(.headline)
            
            Text("Add some expenses to see insights and trends")
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
  }
  
  private func calculateTrends() -> [Trend] {
    let calendar = Calendar.current
    
    // Group current month by category
    let currentGrouped = Dictionary(grouping: currentMonthExpenses) { $0.primaryCategory }
    let lastGrouped = Dictionary(grouping: lastMonthExpenses) { $0.primaryCategory }
    
    var trends: [Trend] = []
    
    for (category, currentExpenses) in currentGrouped {
      let currentTotal = currentExpenses.reduce(0) { $0 + $1.amount }
      let lastTotal = lastGrouped[category]?.reduce(0) { $0 + $1.amount } ?? 0
      
      let change: Double
      if lastTotal > 0 {
        change = ((currentTotal - lastTotal) / lastTotal) * 100
      } else {
        change = currentTotal > 0 ? 100 : 0
      }
      
      trends.append(Trend(
        category: category,
        currentAmount: currentTotal,
        lastAmount: lastTotal,
        change: change
      ))
    }
    
    // Sort by absolute change
    return trends.sorted { abs($0.change) > abs($1.change) }
  }
  
  private func calculateIncome() -> Double {
    // Sum all positive amounts (income) from current month
    // Note: In the updated model, we'd need to track income separately
    // For now, this is a placeholder
    return 0
  }
}

struct Trend: Identifiable {
  let id = UUID()
  let category: ExpenseCategory
  let currentAmount: Double
  let lastAmount: Double
  let change: Double  // Percentage change
}

struct TrendRow: View {
  let trend: Trend
  
  var body: some View {
    HStack(spacing: 12) {
      // Icon
      Image(systemName: trend.category.icon)
        .foregroundColor(trend.category.color)
        .frame(width: 24)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(trend.category.displayName)
          .font(.subheadline)
        
        HStack(spacing: 4) {
          Text("₴\(String(format: "%.0f", trend.currentAmount))")
            .font(.caption)
            .foregroundColor(.secondary)
          
          if trend.lastAmount > 0 {
            Text("(was ₴\(String(format: "%.0f", trend.lastAmount)))")
              .font(.caption2)
              .foregroundColor(.secondary.opacity(0.7))
          }
        }
      }
      
      Spacer()
      
      // Change indicator
      HStack(spacing: 4) {
        Image(systemName: trend.change > 0 ? "arrow.up" : "arrow.down")
          .font(.caption2)
        
        Text("\(String(format: "%.0f", abs(trend.change)))%")
          .font(.caption.bold())
      }
      .foregroundColor(trend.change > 0 ? .red : .green)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background((trend.change > 0 ? Color.red : Color.green).opacity(0.1))
      .cornerRadius(6)
    }
    .padding(.vertical, 4)
  }
}

struct CategoryBreakdownRow: View {
  let category: ExpenseCategory
  let amount: Double
  let percentage: Double
  
  var body: some View {
    VStack(spacing: 8) {
      HStack {
        HStack(spacing: 8) {
          Image(systemName: category.icon)
            .foregroundColor(category.color)
            .frame(width: 20)
          
          Text(category.displayName)
            .font(.subheadline)
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 2) {
          Text("₴\(String(format: "%.0f", amount))")
            .font(.subheadline.bold())
          
          Text("\(String(format: "%.1f", percentage))%")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      // Progress bar
      GeometryReader { geometry in
        RoundedRectangle(cornerRadius: 2)
          .fill(category.color)
          .frame(width: geometry.size.width * (percentage / 100), height: 4)
      }
      .frame(height: 4)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  InsightsView(
    expenses: [],
    viewModel: ExpenseViewModel()
  )
}
