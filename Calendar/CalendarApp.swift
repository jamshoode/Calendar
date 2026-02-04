import SwiftUI
import SwiftData

@main
struct CalendarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppState())
        }
        .modelContainer(for: [Event.self, TimerSession.self, Alarm.self, TimerPreset.self])
    }
}

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
