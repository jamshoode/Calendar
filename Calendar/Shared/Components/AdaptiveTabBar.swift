import SwiftUI

struct AdaptiveTabBar: View {
  @EnvironmentObject var appState: AppState
  #if DEBUG
    @EnvironmentObject var debugSettings: DebugSettings
  #endif
  @State private var showingSettings = false

  var body: some View {
    TabView(selection: $appState.selectedTab) {
      NavigationStack {
        CalendarView()
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Text(Localization.string(.tabCalendar))
                .font(Typography.headline)
                .foregroundColor(.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
              Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                  .foregroundColor(.textSecondary)
              }
            }
          }
      }
      .tabItem {
        Image(systemName: "calendar")
        Text(Localization.string(.tabCalendar))
      }
      .tag(AppState.Tab.calendar)

      NavigationStack {
        TodoView()
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Text(Localization.string(.tabTodo))
                .font(Typography.headline)
                .foregroundColor(.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
              Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                  .foregroundColor(.textSecondary)
              }
            }
          }
      }
      .tabItem {
        Image(systemName: "checkmark.circle")
        Text(Localization.string(.tabTodo))
      }
      .tag(AppState.Tab.tasks)

      NavigationStack {
        ExpensesView()
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Text(Localization.string(.tabExpenses))
                .font(Typography.headline)
                .foregroundColor(.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
              Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                  .foregroundColor(.textSecondary)
              }
            }
          }
      }
      .tabItem {
        Image(systemName: "dollarsign.circle")
        Text(Localization.string(.tabExpenses))
      }
      .tag(AppState.Tab.expenses)

      NavigationStack {
        ClockView()
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Text(Localization.string(.tabClock))
                .font(Typography.headline)
                .foregroundColor(.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
              Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                  .foregroundColor(.textSecondary)
              }
            }
          }
      }
      .tabItem {
        Image(systemName: "clock")
        Text(Localization.string(.tabClock))
      }
      .tag(AppState.Tab.clock)
    }
    .sheet(isPresented: $showingSettings) {
      SettingsSheet(isPresented: $showingSettings)
        .environmentObject(appState)
        #if DEBUG
          .environmentObject(debugSettings)
        #endif
    }
  }
}
