import SwiftUI
import SwiftData

struct AddTemplateSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  
  @State private var title: String = ""
  @State private var amount: String = ""
  @State private var merchant: String = ""
  @State private var frequency: ExpenseFrequency = .monthly
  @State private var category: ExpenseCategory = .other
  @State private var paymentMethod: PaymentMethod = .card
  @State private var notes: String = ""
  @State private var startDate: Date = Date()
  
  var body: some View {
    NavigationStack {
      Form {
        Section("Template Details") {
          TextField("Title (e.g., Netflix)", text: $title)
          TextField("Amount", text: $amount)
            .keyboardType(.decimalPad)
          TextField("Merchant Name", text: $merchant)
        }
        
        Section("Frequency") {
          Picker("Frequency", selection: $frequency) {
            ForEach(ExpenseFrequency.allCases.filter { $0 != .oneTime }, id: \.self) { freq in
              Text(freq.displayName).tag(freq)
            }
          }
          .pickerStyle(.segmented)
          
          DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
        }
        
        Section("Category") {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                CategoryButton(
                  category: cat,
                  isSelected: category == cat,
                  onTap: { category = cat }
                )
              }
            }
            .padding(.vertical, 8)
          }
        }
        
        Section("Payment Method") {
          Picker("Payment Method", selection: $paymentMethod) {
            ForEach(PaymentMethod.allCases, id: \.self) { method in
              HStack {
                Image(systemName: method.icon)
                Text(method.displayName)
              }
              .tag(method)
            }
          }
          .pickerStyle(.segmented)
        }
        
        Section("Notes") {
          TextField("Optional notes", text: $notes, axis: .vertical)
            .lineLimit(3...6)
        }
      }
      .navigationTitle("Add Recurring Expense")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveTemplate()
          }
          .disabled(title.isEmpty || amount.isEmpty || merchant.isEmpty)
        }
      }
    }
  }
  
  private func saveTemplate() {
    guard let amountValue = Double(amount), amountValue > 0 else { return }
    
    let template = RecurringExpenseTemplate(
      title: title,
      amount: amountValue,
      amountTolerance: 0.05,
      categories: [category],
      paymentMethod: paymentMethod,
      currency: .uah,
      merchant: merchant.isEmpty ? title : merchant,
      notes: notes.isEmpty ? nil : notes,
      frequency: frequency,
      startDate: startDate,
      occurrenceCount: 1
    )
    
    modelContext.insert(template)
    try? modelContext.save()
    
    dismiss()
  }
}

struct CategoryButton: View {
  let category: ExpenseCategory
  let isSelected: Bool
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 6) {
        Image(systemName: category.icon)
          .font(.system(size: 20))
          .foregroundColor(isSelected ? .white : category.color)
        
        Text(category.displayName)
          .font(.caption)
          .foregroundColor(isSelected ? .white : .primary)
          .lineLimit(1)
      }
      .frame(width: 72, height: 64)
      .background(isSelected ? category.color : Color(.systemGray6))
      .cornerRadius(12)
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  AddTemplateSheet()
}
