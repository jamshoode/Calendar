import SwiftUI

struct AdaptiveSidebar: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedTab) {
                NavigationLink(value: AppState.Tab.calendar) {
                    Label("Calendar", systemImage: "calendar")
                }
                
                NavigationLink(value: AppState.Tab.timer) {
                    Label("Timer", systemImage: "timer")
                }
                
                NavigationLink(value: AppState.Tab.alarm) {
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
            case nil:
                NotFoundView()
            }
        }
    }
}
