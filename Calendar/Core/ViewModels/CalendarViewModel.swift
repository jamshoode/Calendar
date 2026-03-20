import SwiftUI
import SwiftData
import Combine

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date().startOfMonth
    @Published var selectedDate: Date? = Date()
    @Published private(set) var monthOffsetRange: ClosedRange<Int> = -6...6

    private let expansionStep = 6

    var monthOffsets: [Int] {
        Array(monthOffsetRange)
    }

    func month(for offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth
    }

    func moveToPreviousMonth() {
        let previous = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        recenter(on: previous)
    }

    func moveToNextMonth() {
        let next = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        recenter(on: next)
    }

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func recenter(on date: Date) {
        currentMonth = date.startOfMonth
        monthOffsetRange = -6...6
    }

    func expandRangeIfNeeded(for offset: Int) {
        if offset <= monthOffsetRange.lowerBound + 1 {
            monthOffsetRange = (monthOffsetRange.lowerBound - expansionStep)...monthOffsetRange.upperBound
        } else if offset >= monthOffsetRange.upperBound - 1 {
            monthOffsetRange = monthOffsetRange.lowerBound...(monthOffsetRange.upperBound + expansionStep)
        }
    }
}
