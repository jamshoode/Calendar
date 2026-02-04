import SwiftUI
import SwiftData

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Query private var presets: [TimerPreset]
    @State private var selectedTab: TimerTab = .countdown
    
    enum TimerTab {
        case countdown
        case pomodoro
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Picker("Timer Type", selection: $selectedTab) {
                Text("Countdown").tag(TimerTab.countdown)
                Text("Pomodoro").tag(TimerTab.pomodoro)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            switch selectedTab {
            case .countdown:
                CountdownView(viewModel: viewModel, presets: presets)
            case .pomodoro:
                PomodoroView(viewModel: viewModel)
            }
        }
        .padding(.top)
    }
}
