import SwiftUI
import SwiftData

@main
struct CalendarApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    @StateObject private var appState = AppState()
    #if DEBUG
    @StateObject private var debugSettings = DebugSettings()
    #endif
    
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            ContentView()
                .environmentObject(appState)
                .environmentObject(debugSettings)
                .preferredColorScheme(debugSettings.themeOverride.colorScheme)
                .modelContainer(for: [Event.self, TodoItem.self, TodoCategory.self, Expense.self, RecurringExpenseTemplate.self, CSVImportSession.self, Alarm.self, TimerPreset.self, TimerSession.self])
            #else
            ContentView()
                .environmentObject(appState)
                .modelContainer(for: [Event.self, TodoItem.self, TodoCategory.self, Expense.self, RecurringExpenseTemplate.self, CSVImportSession.self, Alarm.self, TimerPreset.self, TimerSession.self])
            #endif
        }
    }
}

struct ContentView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.modelContext) private var modelContext
  @State private var showingSettings = false
  
  var body: some View {
    ZStack {
      // Atmospheric Background
      MeshGradientView()
        .ignoresSafeArea()
        .animation(nil, value: appState.selectedTab)
      
      // Main Content Area
      Group {
        if let selectedTab = appState.selectedTab {
            switch selectedTab {
            case .calendar:
              NavigationStack { CalendarView() }
            case .tasks:
              NavigationStack { TodoView() }
            case .expenses:
              NavigationStack { ExpensesView() }
            case .clock:
              NavigationStack { ClockView() }
            case .weather:
              NavigationStack { WeatherView() }
            }
        } else {
            Text(Localization.string(.selectTabPrompt))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .opacity(1)
      .animation(.easeOut(duration: 0.15), value: appState.selectedTab)
      
      // Floating Tab Bar
      VStack {
          Spacer()
          FloatingTabBar(selectedTab: $appState.selectedTab)
      }
      .ignoresSafeArea(.keyboard)
      
      // Floating error banner
      FloatingErrorView()
        .zIndex(10)
    }
    .sheet(isPresented: $showingSettings) {
        SettingsSheet(isPresented: $showingSettings)
    }
    .onAppear {
      EventViewModel().syncEventsToWidget(context: modelContext)
      RecurringExpenseService.shared.generateRecurringExpenses(context: modelContext)
      TodoViewModel().cleanupCompletedTodos(context: modelContext)
      TodoViewModel().rescheduleAllNotifications(context: modelContext)
      
      // Check for missed recurring payments
      let missed = RecurringExpenseService.shared.checkMissedPayments(context: modelContext)
      if !missed.isEmpty {
        print("⚠️ \(missed.count) missed recurring payment(s) detected")
      }
    }
  }
}
