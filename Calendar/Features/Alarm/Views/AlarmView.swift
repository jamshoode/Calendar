import SwiftUI
import SwiftData

struct AlarmView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @Query private var alarms: [Alarm]
    @State private var showingTimePicker = false
    
    var body: some View {
        VStack(spacing: 24) {
            if let alarm = alarms.first {
                AlarmCard(alarm: alarm, viewModel: viewModel)
            } else {
                EmptyAlarmView(onAdd: { showingTimePicker = true })
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView { time in
                viewModel.createAlarm(time: time, context: modelContext)
                showingTimePicker = false
            }
        }
    }
    
    @Environment(\.modelContext) private var modelContext
}

struct AlarmCard: View {
    let alarm: Alarm
    @ObservedObject var viewModel: AlarmViewModel
    @State private var showingTimePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                AlarmToggle(isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in viewModel.toggleAlarm(alarm: alarm, context: modelContext) }
                ))
            }
            
            Button(action: { showingTimePicker = true }) {
                Text(Formatters.timeFormatter.string(from: alarm.time))
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .foregroundColor(alarm.isEnabled ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Alarm time: \(Formatters.timeFormatter.string(from: alarm.time))")
            .accessibilityHint("Double tap to edit alarm time")
            
            if alarm.isEnabled {
                Text(viewModel.timeRemainingText(for: alarm))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .accessibilityLabel(viewModel.timeRemainingText(for: alarm))
            }
            
            HStack(spacing: 12) {
                GlassButton(title: "Edit", icon: "pencil") {
                    showingTimePicker = true
                }
                .accessibilityLabel("Edit alarm time")
                
                GlassButton(title: "Delete", icon: "trash", isPrimary: true) {
                    viewModel.deleteAlarm(alarm: alarm, context: modelContext)
                }
                .accessibilityLabel("Delete alarm")
            }
        }
        .padding(24)
        .glassBackground(cornerRadius: 24)
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(initialTime: alarm.time) { time in
                alarm.time = time
                if alarm.isEnabled {
                    NotificationService.shared.cancelAlarmNotifications()
                    NotificationService.shared.scheduleAlarmNotification(date: time)
                }
                showingTimePicker = false
            }
        }
    }
    
    @Environment(\.modelContext) private var modelContext
}

struct EmptyAlarmView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "alarm")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            
            Text("No Alarm Set")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("Tap the button below to set an alarm")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            GlassButton(title: "Set Alarm", icon: "plus", isPrimary: true, action: onAdd)
                .padding(.top, 20)
                .accessibilityLabel("Set new alarm")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
