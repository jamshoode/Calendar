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
          .navigationTitle(Localization.string(.tabCalendar))
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
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
          .navigationTitle(Localization.string(.tabTodo))
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
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
          .navigationTitle(Localization.string(.tabExpenses))
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
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
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
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
