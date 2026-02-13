import SwiftData
import SwiftUI

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
    VStack(spacing: 12) {
      // Custom Glass Picker
      HStack(spacing: 0) {
          Button {
              withAnimation { selectedTab = .countdown }
          } label: {
              Text(Localization.string(.countdown))
                  .font(.system(size: 13, weight: .bold))
                  .foregroundColor(selectedTab == .countdown ? .white : .textSecondary)
                  .frame(maxWidth: .infinity)
                  .frame(height: 36)
                  .background(selectedTab == .countdown ? Color.accentColor : Color.clear)
                  .clipShape(RoundedRectangle(cornerRadius: 10))
          }
          .buttonStyle(.plain)
          
          Button {
              withAnimation { selectedTab = .pomodoro }
          } label: {
              Text(Localization.string(.pomodoro))
                  .font(.system(size: 13, weight: .bold))
                  .foregroundColor(selectedTab == .pomodoro ? .white : .textSecondary)
                  .frame(maxWidth: .infinity)
                  .frame(height: 36)
                  .background(selectedTab == .pomodoro ? Color.accentColor : Color.clear)
                  .clipShape(RoundedRectangle(cornerRadius: 10))
          }
          .buttonStyle(.plain)
      }
      .padding(4)
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 14))
      .glassHalo(cornerRadius: 14)
      .padding(.horizontal, 40)

      switch selectedTab {
      case .countdown:
        CountdownView(viewModel: countdownViewModel, presets: presets)
          .transition(.opacity)
      case .pomodoro:
        PomodoroView(viewModel: pomodoroViewModel)
          .transition(.opacity)
      }
    }
    .padding(.top, 8)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
    .onAppear {
      if presets.isEmpty {
        for preset in TimerPreset.defaultPresets {
          modelContext.insert(preset)
        }
      }
    }
  }
}
