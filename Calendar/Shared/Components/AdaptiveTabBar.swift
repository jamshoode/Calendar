import SwiftUI

struct AdaptiveTabBar: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text(Localization.string(.tabCalendar))
                }
                .tag(AppState.Tab.calendar)
            
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
}
