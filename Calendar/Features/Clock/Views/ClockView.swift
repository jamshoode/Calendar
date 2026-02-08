import SwiftUI
import SwiftData

struct ClockView: View {
  @State private var selectedSection: ClockSection = .timer

  enum ClockSection {
    case timer
    case alarm
  }

  var body: some View {
    VStack(spacing: Spacing.lg) {
      // Section toggle
      Picker("Section", selection: $selectedSection) {
        Text(Localization.string(.tabTimer)).tag(ClockSection.timer)
        Text(Localization.string(.tabAlarm)).tag(ClockSection.alarm)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, Spacing.md)

      switch selectedSection {
      case .timer:
        TimerView()
          .transition(.opacity)
      case .alarm:
        AlarmView()
          .transition(.opacity)
      }
    }
    .padding(.top, Spacing.sm)
    .animation(.easeInOut(duration: 0.3), value: selectedSection)
    .background(Color.backgroundPrimary)
  }
}
