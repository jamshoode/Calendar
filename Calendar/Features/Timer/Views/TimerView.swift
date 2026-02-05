import SwiftUI
import SwiftData

struct TimerView: View {
    @StateObject private var countdownViewModel = TimerViewModel(id: "countdown")
    @StateObject private var pomodoroViewModel = TimerViewModel(id: "pomodoro")
    @Query private var presets: [TimerPreset]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TimerTab = .countdown
    
    enum TimerTab {
        case countdown
        case pomodoro
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Picker("Timer Type", selection: $selectedTab) {
                Text(Localization.string(.countdown)).tag(TimerTab.countdown)
                Text(Localization.string(.pomodoro)).tag(TimerTab.pomodoro)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityLabel(Localization.string(.selectTimerType))
            
            switch selectedTab {
            case .countdown:
                CountdownView(viewModel: countdownViewModel, presets: presets)
                    .transition(.opacity)
            case .pomodoro:
                PomodoroView(viewModel: pomodoroViewModel)
                    .transition(.opacity)
            }
        }
        .padding(.top)
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .onAppear {
            if presets.isEmpty {
                for preset in TimerPreset.defaultPresets {
                    modelContext.insert(preset)
                }
            }
        }
    }
}
