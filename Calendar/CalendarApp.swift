import SwiftUI
import SwiftData

@main
struct CalendarApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("Calendar", systemImage: "calendar") {
            MenuBarContentView()
                .frame(width: 350, height: 500)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(for: [Event.self, TimerSession.self, Alarm.self, TimerPreset.self])
        #else
        WindowGroup {
            ContentView()
                .environmentObject(AppState())
        }
        .modelContainer(for: [Event.self, TimerSession.self, Alarm.self, TimerPreset.self])
        #endif
    }
}

#if os(macOS)
struct MenuBarContentView: View {
    @State private var selectedTab: Tab = .calendar
    
    enum Tab {
        case calendar
        case timer
        case alarm
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Image(systemName: "calendar").tag(Tab.calendar)
                Image(systemName: "timer").tag(Tab.timer)
                Image(systemName: "alarm").tag(Tab.alarm)
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            switch selectedTab {
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
#endif

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            #if os(iOS)
            AdaptiveTabBar()
            #else
            AdaptiveSidebar()
            #endif
        }
    }
}
