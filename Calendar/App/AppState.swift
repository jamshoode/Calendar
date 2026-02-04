import SwiftUI
import Combine

class AppState: ObservableObject {
    var selectedTab: Tab = .calendar
    var selectedDate: Date = Date()
    
    enum Tab {
        case calendar
        case timer
        case alarm
    }
}
