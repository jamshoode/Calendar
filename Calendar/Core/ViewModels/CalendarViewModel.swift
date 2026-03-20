import Combine
import SwiftData
import SwiftUI

class CalendarViewModel: ObservableObject {
  @Published var currentMonth: Date = Date().startOfMonth
  @Published var selectedDate: Date? = Date()
  private let monthOffsetRange: ClosedRange<Int> = 0...12

  var monthOffsets: [Int] {
    Array(monthOffsetRange)
  }

  func month(for offset: Int) -> Date {
    Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth
  }

  func moveToPreviousMonth() {
    let previous =
      Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
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
  }
}
