import SwiftUI

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    let events: [Event]
    
    var body: some View {
        VStack(spacing: 4) {
            Text(date.formattedDay)
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.2) : Color.clear))
                )
            
            if !events.isEmpty {
                EventIndicator(events: events)
            }
        }
        .frame(height: 50)
        .opacity(isCurrentMonth ? 1.0 : 0.4)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }
}
