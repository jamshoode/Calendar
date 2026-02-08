import Combine
import Foundation

class AppState: ObservableObject {
  @Published var selectedTab: Tab? = .calendar
  @Published var selectedDate: Date = Date()

  enum Tab: String, CaseIterable, Identifiable {
    case calendar
    case tasks
    case expenses
    case clock

    var id: String { rawValue }
  }

  init() {}
}
