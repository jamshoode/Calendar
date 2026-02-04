import SwiftUI

struct AdaptiveSidebar: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink(
                    destination: CalendarView(),
                    tag: AppState.Tab.calendar,
                    selection: $appState.selectedTab
                ) {
                    Label("Calendar", systemImage: "calendar")
                }
                
                NavigationLink(
                    destination: TimerView(),
                    tag: AppState.Tab.timer,
                    selection: $appState.selectedTab
                ) {
                    Label("Timer", systemImage: "timer")
                }
                
                NavigationLink(
                    destination: AlarmView(),
                    tag: AppState.Tab.alarm,
                    selection: $appState.selectedTab
                ) {
                    Label("Alarm", systemImage: "alarm")
                }
            }
            .navigationTitle("Calendar")
        } detail: {
            switch appState.selectedTab {
            case .calendar:
                CalendarView()
            case .timer:
                TimerView()
            case .alarm:
                AlarmView()
            }
        }
    }
}
