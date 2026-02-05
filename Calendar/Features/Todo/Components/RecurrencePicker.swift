import SwiftUI

struct RecurrencePicker: View {
  @Binding var recurrenceType: RecurrenceType?
  @Binding var interval: Int
  @Binding var endDate: Date?

  @State private var hasEndDate: Bool = false
  @State private var selectedEndDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Picker(Localization.string(.recurring), selection: $recurrenceType) {
        Text(Localization.string(.none)).tag(nil as RecurrenceType?)
        ForEach(RecurrenceType.allCases, id: \.self) { type in
          Text(type.displayName).tag(type as RecurrenceType?)
        }
      }

      if recurrenceType != nil {
        HStack {
          Text(intervalLabel)
            .foregroundColor(.secondary)

          Picker("", selection: $interval) {
            ForEach(1...12, id: \.self) { num in
              Text("\(num)").tag(num)
            }
          }
          .pickerStyle(.menu)
          .frame(width: 80)
        }

        Toggle(isOn: $hasEndDate) {
          Text(Localization.string(.endDate))
        }
        .onChange(of: hasEndDate) { _, newValue in
          endDate = newValue ? selectedEndDate : nil
        }

        if hasEndDate {
          DatePicker(
            "",
            selection: $selectedEndDate,
            in: Date()...,
            displayedComponents: .date
          )
          .onChange(of: selectedEndDate) { _, newValue in
            endDate = newValue
          }
        }
      }
    }
    .onAppear {
      hasEndDate = endDate != nil
      if let end = endDate {
        selectedEndDate = end
      }
    }
  }

  private var intervalLabel: String {
    guard let type = recurrenceType else { return "" }
    switch type {
    case .weekly: return Localization.string(.everyNWeeks(interval))
    case .monthly: return Localization.string(.everyNMonths(interval))
    case .yearly: return Localization.string(.everyNYears(interval))
    }
  }
}
