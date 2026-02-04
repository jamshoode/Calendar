import Foundation

struct Constants {
    static let appName = "Calendar"
    
    struct Timer {
        static let pomodoroWorkDuration: TimeInterval = 25 * 60
        static let pomodoroShortBreakDuration: TimeInterval = 5 * 60
        static let pomodoroLongBreakDuration: TimeInterval = 15 * 60
        static let pomodoroSessionsBeforeLongBreak = 4
        static let defaultSnoozeDuration: TimeInterval = 5 * 60
    }
    
    struct UI {
        static let glassCornerRadius: CGFloat = 20
        static let glassCornerRadiusSmall: CGFloat = 12
        static let glassBorderWidth: CGFloat = 0.5
        static let glassBorderOpacity: Double = 0.2
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
    }
    
    struct Storage {
        static let appGroupIdentifier = "group.com.yourcompany.calendar"
    }
}
