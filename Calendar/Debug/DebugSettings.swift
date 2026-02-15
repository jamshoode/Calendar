import Combine
import SwiftUI
import WidgetKit

#if DEBUG
  class DebugSettings: ObservableObject {
    // Appearance
    @Published var themeOverride: ThemeOverride = .system {
      didSet {
        UserDefaults.standard.set(themeOverride.rawValue, forKey: "debug_themeOverride")
        UserDefaults(suiteName: "group.com.shoode.calendar")?.set(
          themeOverride.rawValue, forKey: "debug_themeOverride")
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
      }
    }

    // Feature Flags / Mocks
    @Published var showBorders: Bool = false
    @Published var mockDates: Bool = false

    init() {
      if let savedTheme = UserDefaults.standard.string(forKey: "debug_themeOverride"),
        let theme = ThemeOverride(rawValue: savedTheme)
      {
        self.themeOverride = theme
      }
    }

    enum ThemeOverride: String, CaseIterable, Identifiable {
      case system = "System"
      case light = "Light"
      case dark = "Dark"

      var id: String { rawValue }

      var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
      }
    }
  }
#endif
