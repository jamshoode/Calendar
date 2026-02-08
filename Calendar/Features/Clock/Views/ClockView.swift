import SwiftData
import SwiftUI

struct ClockView: View {
  @State private var selectedSection: ClockSection = .timer

  enum ClockSection {
    case timer
    case alarm
  }

  var body: some View {
    VStack(spacing: 0) {
      switch selectedSection {
      case .timer:
        TimerView()
          .transition(.opacity)
      case .alarm:
        AlarmView()
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: selectedSection)
    .background(Color.backgroundPrimary)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Picker("Section", selection: $selectedSection) {
          Text(Localization.string(.tabTimer)).tag(ClockSection.timer)
          Text(Localization.string(.tabAlarm)).tag(ClockSection.alarm)
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
      }
    }
  }
}
