import SwiftUI

struct AdaptiveTabBar: View {
  @EnvironmentObject var appState: AppState
  #if DEBUG
    @EnvironmentObject var debugSettings: DebugSettings
  #endif
  @State private var showingSettings = false

  private var currentTabTitle: String {
    switch appState.selectedTab {
    case .calendar:
      return Localization.string(.tabCalendar)
    case .todo:
      return Localization.string(.tabTodo)
    case .timer:
      return Localization.string(.tabTimer)
    case .alarm:
      return Localization.string(.tabAlarm)
    case .none:
      return ""
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      TopBarView(title: currentTabTitle) {
        withAnimation(.easeInOut(duration: 0.25)) {
          showingSettings = true
        }
      }

      TabView(selection: $appState.selectedTab) {
        CalendarView()
          .tabItem {
            Image(systemName: "calendar")
            Text(Localization.string(.tabCalendar))
          }
          .tag(AppState.Tab.calendar)

        TodoView()
          .tabItem {
            Image(systemName: "checkmark.circle")
            Text(Localization.string(.tabTodo))
          }
          .tag(AppState.Tab.todo)

        TimerView()
          .tabItem {
            Image(systemName: "timer")
            Text(Localization.string(.tabTimer))
          }
          .tag(AppState.Tab.timer)

        AlarmView()
          .tabItem {
            Image(systemName: "alarm")
            Text(Localization.string(.tabAlarm))
          }
          .tag(AppState.Tab.alarm)
      }
    }
    .sideSheet(isPresented: $showingSettings) {
      SettingsSheet(isPresented: $showingSettings)
        .environmentObject(appState)
        #if DEBUG
          .environmentObject(debugSettings)
        #endif
    }
  }
}
