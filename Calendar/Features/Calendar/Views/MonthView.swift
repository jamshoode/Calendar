import SwiftUI

struct MonthView: View {
    let currentMonth: Date
    let selectedDate: Date?
    let events: [Event]
    let onSelectDate: (Date) -> Void
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    private var days: [Date?] {
        let startOfMonth = currentMonth.startOfMonth
        let endOfMonth = currentMonth.endOfMonth
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let adjustedFirstWeekday = (firstWeekday + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: adjustedFirstWeekday)
        
        var currentDate = startOfMonth
        while currentDate <= endOfMonth {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        let remainingCells = (7 - (days.count % 7)) % 7
        days.append(contentsOf: Array(repeating: nil, count: remainingCells))
        
        return days
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: daysInWeek), spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    let isSelected = selectedDate != nil && date.isSameDay(as: selectedDate!)
                    let isToday = date.isToday
                    let dayEvents = eventsForDate(date)
                    
                    DayCell(
                        date: date,
                        isCurrentMonth: isCurrentMonth,
                        isSelected: isSelected,
                        isToday: isToday,
                        events: dayEvents
                    )
                    .onTapGesture {
                        onSelectDate(date)
                    }
                } else {
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func eventsForDate(_ date: Date) -> [Event] {
        events.filter { $0.date.isSameDay(as: date) }
    }
}
