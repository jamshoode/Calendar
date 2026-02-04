import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    
    let date: Date
    let event: Event?
    let onSave: (String, String?, String, Date, TimeInterval?) -> Void
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedColor: String = "blue"
    @State private var selectedDate: Date = Date()
    @State private var reminderSelection: TimeInterval = 0
    
    private let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow"]
    
    private let reminders: [(String, TimeInterval)] = [
        ("None", 0),
        ("At time of event", 0.1),
        ("15 minutes before", 15 * 60),
        ("30 minutes before", 30 * 60),
        ("1 hour before", 60 * 60),
        ("2 hours before", 2 * 60 * 60),
        ("1 day before", 24 * 60 * 60)
    ]
    
    init(date: Date, event: Event? = nil, onSave: @escaping (String, String?, String, Date, TimeInterval?) -> Void) {
        self.date = date
        self.event = event
        self.onSave = onSave
        
        if let event = event {
            _title = State(initialValue: event.title)
            _notes = State(initialValue: event.notes ?? "")
            _selectedColor = State(initialValue: event.color)
            _selectedDate = State(initialValue: event.date)
            _reminderSelection = State(initialValue: event.reminderInterval ?? 0)
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
                    DatePicker("Starts", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Reminder", selection: $reminderSelection) {
                        ForEach(reminders, id: \.1) { label, value in
                            Text(label).tag(value)
                        }
                    }
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
                        let reminder = reminderSelection == 0 ? nil : reminderSelection
                        onSave(title, notes.isEmpty ? nil : notes, selectedColor, selectedDate, reminder)
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
