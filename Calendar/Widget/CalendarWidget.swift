import WidgetKit
import SwiftUI

@main
struct CalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalendarWidget()
    }
}

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("Shows the current week and timer/alarm status.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let weekDays: [WeekDay]
    let hasTimer: Bool
    let hasAlarm: Bool
}

struct WeekDay: Identifiable {
    let id = UUID()
    let name: String
    let date: Int
    let isToday: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), weekDays: sampleWeekDays(), hasTimer: false, hasAlarm: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let entry = CalendarEntry(date: Date(), weekDays: sampleWeekDays(), hasTimer: false, hasAlarm: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [CalendarEntry] = []
        let currentDate = Date()
        
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = CalendarEntry(
                date: entryDate,
                weekDays: getWeekDays(for: entryDate),
                hasTimer: UserDefaults.shared.bool(forKey: "hasActiveTimer"),
                hasAlarm: UserDefaults.shared.bool(forKey: "hasActiveAlarm")
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func sampleWeekDays() -> [WeekDay] {
        [
            WeekDay(name: "Mon", date: 9, isToday: false),
            WeekDay(name: "Tue", date: 10, isToday: true),
            WeekDay(name: "Wed", date: 11, isToday: false),
            WeekDay(name: "Thu", date: 12, isToday: false),
            WeekDay(name: "Fri", date: 13, isToday: false),
            WeekDay(name: "Sat", date: 14, isToday: false),
            WeekDay(name: "Sun", date: 15, isToday: false)
        ]
    }
    
    private func getWeekDays(for date: Date) -> [WeekDay] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let adjustedWeekday = (weekday + 5) % 7
        
        var weekDays: [WeekDay] = []
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        for i in 0..<7 {
            let dayDate = calendar.date(byAdding: .day, value: i - adjustedWeekday, to: date)!
            let dayOfMonth = calendar.component(.day, from: dayDate)
            let isToday = calendar.isDate(dayDate, inSameDayAs: date)
            
            weekDays.append(WeekDay(
                name: dayNames[i],
                date: dayOfMonth,
                isToday: isToday
            ))
        }
        
        return weekDays
    }
}

struct CalendarWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(entry.weekDays) { day in
                    WeekDayCell(day: day)
                }
            }
            
            HStack(spacing: 16) {
                if entry.hasTimer {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 14))
                        Text("Active")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.accentColor)
                }
                
                if entry.hasAlarm {
                    HStack(spacing: 4) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 14))
                        Text("Set")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.orange)
                }
                
                if !entry.hasTimer && !entry.hasAlarm {
                    Text("No active timer or alarm")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

struct LargeWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                ForEach(entry.weekDays) { day in
                    WeekDayCell(day: day, large: true)
                }
            }
            
            HStack(spacing: 20) {
                StatusCard(
                    icon: "timer",
                    title: "Timer",
                    status: entry.hasTimer ? "Active" : "Off",
                    color: .accentColor
                )
                
                StatusCard(
                    icon: "alarm.fill",
                    title: "Alarm",
                    status: entry.hasAlarm ? "Set" : "Off",
                    color: .orange
                )
            }
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

struct WeekDayCell: View {
    let day: WeekDay
    var large: Bool = false
    
    var body: some View {
        VStack(spacing: large ? 8 : 4) {
            Text(day.name)
                .font(.system(size: large ? 14 : 11, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("\(day.date)")
                .font(.system(size: large ? 20 : 16, weight: day.isToday ? .bold : .regular))
                .foregroundColor(day.isToday ? .accentColor : .primary)
                .frame(width: large ? 36 : 28, height: large ? 36 : 28)
                .background(
                    Circle()
                        .fill(day.isToday ? Color.accentColor.opacity(0.2) : Color.clear)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatusCard: View {
    let icon: String
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(status)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: "group.com.yourcompany.calendar") ?? .standard
    }
}
