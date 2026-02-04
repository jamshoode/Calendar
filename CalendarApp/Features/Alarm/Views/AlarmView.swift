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
            
            Text(alarm.time.formattedTime)
                .font(.system(size: 72, weight: .light, design: .rounded))
                .foregroundColor(alarm.isEnabled ? .primary : .secondary)
            
            if alarm.isEnabled {
                Text(viewModel.timeRemainingText(for: alarm))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                GlassButton(title: "Edit", icon: "pencil") {
                }
                
                GlassButton(title: "Delete", icon: "trash", isPrimary: true) {
                    viewModel.deleteAlarm(alarm: alarm, context: modelContext)
                }
            }
        }
        .padding(24)
        .glassBackground(cornerRadius: 24)
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
            
            Text("No Alarm Set")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("Tap the button below to set an alarm")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            GlassButton(title: "Set Alarm", icon: "plus", isPrimary: true, action: onAdd)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Date {
    var formattedTime: String {
        Formatters.timeFormatter.string(from: self)
    }
}
