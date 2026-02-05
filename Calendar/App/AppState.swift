import Foundation
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Tab? = .calendar
    @Published var selectedDate: Date = Date()
    
    enum Tab: String, CaseIterable, Identifiable {
        case calendar
        case timer
        case alarm
        #if DEBUG
        case debug
        #endif

        
        var id: String { rawValue }
    }
    
    init() {}
}
