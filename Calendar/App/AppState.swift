import SwiftUI
import SwiftData
import Combine

@Observable
class AppState {
    var selectedTab: Tab = .calendar
    var selectedDate: Date = Date()
    
    enum Tab {
        case calendar
        case timer
        case alarm
    }
}
