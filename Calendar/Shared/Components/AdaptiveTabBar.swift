import SwiftUI

struct AdaptiveTabBar: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(AppState.Tab.calendar)
            
            TimerView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Timer")
                }
                .tag(AppState.Tab.timer)
            
            AlarmView()
                .tabItem {
                    Image(systemName: "alarm")
                    Text("Alarm")
                }
                .tag(AppState.Tab.alarm)
        }
    }
}
