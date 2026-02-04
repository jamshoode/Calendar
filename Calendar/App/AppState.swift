import SwiftUI
import SwiftData
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .calendar
    @Published var selectedDate: Date = Date()
    
    enum Tab {
        case calendar
        case timer
        case alarm
    }
}
