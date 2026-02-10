import Combine
import SwiftData
import SwiftUI

@main
struct CalendarApp: App {
  #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #endif

  #if DEBUG
    @StateObject private var debugSettings = DebugSettings()
  #endif

  @StateObject private var appState = AppState()

  private static let sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Event.self, TimerSession.self, Alarm.self, TimerPreset.self, TodoItem.self,
      TodoCategory.self, Expense.self,
    ])

    // Try app group container first (where data was previously stored),
    // fall back to default sandbox if the group isn't available
    if let groupURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.shoode.calendar")
    {
      let storeURL =
        groupURL
        .appendingPathComponent("Library")
        .appendingPathComponent("Application Support")
        .appendingPathComponent("default.store")
      let config = ModelConfiguration(schema: schema, url: storeURL)
      do {
        return try ModelContainer(for: schema, configurations: [config])
      } catch {
        ErrorPresenter.presentOnMain(error)
        // Fall through to default container creation
      }
    }

    let config = ModelConfiguration(schema: schema, groupContainer: .none)
    do {
      return try ModelContainer(for: schema, configurations: [config])
    } catch {
      // Surface error to user and try a fallback
      ErrorPresenter.presentOnMain(error)
      do {
        return try ModelContainer(for: schema)
      } catch {
        ErrorPresenter.presentOnMain(error)
        fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
      }
    }
  }()

  var body: some Scene {
    #if os(macOS)
      MenuBarExtra("Calendar", systemImage: "calendar") {
        MenuBarContentView()
          .frame(width: 350, height: 500)
      }
      .menuBarExtraStyle(.window)
      .modelContainer(Self.sharedModelContainer)
    #else
      WindowGroup {
        ContentView()
          .environmentObject(appState)
          #if DEBUG
            .environmentObject(debugSettings)
            .preferredColorScheme(debugSettings.themeOverride.colorScheme)
          #endif
      }
      .modelContainer(Self.sharedModelContainer)
    #endif
  }
}

#if os(macOS)
  struct MenuBarContentView: View {
    @State private var selectedTab: Tab = .calendar

    enum Tab {
      case calendar
      case todo
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
          MenuBarTabButton(icon: "checkmark.circle", isSelected: selectedTab == .todo) {
            selectedTab = .todo
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
        .background(Color.backgroundPrimary)

        Divider()

        // Content
        ZStack {
          switch selectedTab {
          case .calendar:
            CalendarView()
          case .todo:
            TodoView()
          case .timer:
            TimerView()
          case .alarm:
            AlarmView()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .background(Color.backgroundPrimary)
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
    ZStack {
      Group {
        #if os(iOS)
          AdaptiveTabBar()
        #else
          AdaptiveSidebar()
        #endif
      }

      // Floating error banner
      FloatingErrorView()
        .zIndex(1)
    }
  }
}
