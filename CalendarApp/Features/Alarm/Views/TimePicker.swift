import SwiftUI

struct TimePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onConfirm: (Date) -> Void
    
    @State private var selectedTime: Date = Date()
    
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
                
                Text("Alarm will ring at \(Formatters.timeFormatter.string(from: selectedTime))")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                
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
