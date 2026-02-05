import SwiftUI
import SwiftData

@main
struct CalendarApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    #if DEBUG
    @StateObject private var debugSettings = DebugSettings()
    #endif
    
    @StateObject private var appState = AppState()
    
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
                .environmentObject(appState)
                #if DEBUG
                .environmentObject(debugSettings)
                .preferredColorScheme(debugSettings.themeOverride.colorScheme)
                #endif
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
            // Custom Tab Bar
            HStack(spacing: 0) {
                MenuBarTabButton(icon: "calendar", isSelected: selectedTab == .calendar) {
                    selectedTab = .calendar
                }
                MenuBarTabButton(icon: "timer", isSelected: selectedTab == .timer) {
                    selectedTab = .timer
                }
                MenuBarTabButton(icon: "alarm.fill", isSelected: selectedTab == .alarm) {
                    selectedTab = .alarm
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Content
            ZStack {
                switch selectedTab {
                case .calendar:
                    CalendarView()
                case .timer:
                    TimerView()
                case .alarm:
                    AlarmView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct MenuBarTabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
