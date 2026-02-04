import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    
    let date: Date
    let event: Event?
    let onSave: (String, String?, String) -> Void
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedColor: String = "blue"
    @State private var selectedDate: Date = Date()
    
    private let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow"]
    
    init(date: Date, event: Event? = nil, onSave: @escaping (String, String?, String) -> Void) {
        self.date = date
        self.event = event
        self.onSave = onSave
        
        if let event = event {
            _title = State(initialValue: event.title)
            _notes = State(initialValue: event.notes ?? "")
            _selectedColor = State(initialValue: event.color)
            _selectedDate = State(initialValue: event.date)
        } else {
            _selectedDate = State(initialValue: date)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    
                    if #available(iOS 16.0, *) {
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    } else {
                        TextField("Notes", text: $notes)
                    }
                }
                
                Section("Date & Time") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(colors, id: \.self) { color in
                                ColorCircle(color: color, isSelected: selectedColor == color) {
                                    selectedColor = color
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, notes.isEmpty ? nil : notes, selectedColor)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct ColorCircle: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.eventColor(named: color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .shadow(color: Color.eventColor(named: color).opacity(0.3), radius: isSelected ? 4 : 0)
        }
        .buttonStyle(.plain)
    }
}
