import SwiftUI

struct TimePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let initialTime: Date
    let onConfirm: (Date) -> Void
    
    @State private var selectedTime: Date
    
    init(initialTime: Date = Date(), onConfirm: @escaping (Date) -> Void) {
        self.initialTime = initialTime
        self.onConfirm = onConfirm
        _selectedTime = State(initialValue: initialTime)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                DatePicker(
                    "Select Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 200)
                .accessibilityLabel("Time picker")
                
                Text("Alarm will ring at \(Formatters.timeFormatter.string(from: selectedTime))")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Alarm set for \(Formatters.timeFormatter.string(from: selectedTime))")
                
                Spacer()
            }
            .padding()
            .navigationTitle("Set Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onConfirm(selectedTime)
                    }
                }
            }
        }
    }
}
