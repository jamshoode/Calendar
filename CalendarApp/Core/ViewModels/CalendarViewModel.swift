import SwiftUI
import SwiftData

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date()
    
    func moveToPreviousMonth() {
        currentMonth = currentMonth.addingMonths(-1)
    }
    
    func moveToNextMonth() {
        currentMonth = currentMonth.addingMonths(1)
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
    }
}
