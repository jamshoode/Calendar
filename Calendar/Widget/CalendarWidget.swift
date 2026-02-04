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
        VStack(alignment: .leading, spacing: 0) {
            // Header Content
            if !entry.hasTimer && !entry.hasAlarm {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(entry.date.formatted(.dateTime.month().day()))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 12)
            } else {
                HStack(spacing: 12) {
                    if entry.hasTimer {
                        Label("Timer Running", systemImage: "timer")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.accentColor.gradient))
                    }
                    
                    if entry.hasAlarm {
                        Label("Alarm Set", systemImage: "alarm.fill")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.orange.gradient))
                    }
                }
                .padding(.bottom, 12)
            }
            
            Spacer()
            
            // Week Row
            HStack(spacing: 0) {
                ForEach(entry.weekDays) { day in
                    WeekDayCell(day: day)
                }
            }
        }
        .padding()
        .containerBackground(Color.white, for: .widget)
    }
}

struct LargeWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 0) {
                ForEach(entry.weekDays) { day in
                    WeekDayCell(day: day, large: true)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Status")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    StatusCard(
                        icon: "timer",
                        title: "Timer",
                        status: entry.hasTimer ? "Active" : "Idle",
                        color: .accentColor,
                        isActive: entry.hasTimer
                    )
                    
                    StatusCard(
                        icon: "alarm.fill",
                        title: "Alarm",
                        status: entry.hasAlarm ? "Set" : "Off",
                        color: .orange,
                        isActive: entry.hasAlarm
                    )
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(Color.white, for: .widget)
    }
}

struct WeekDayCell: View {
    let day: WeekDay
    var large: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            Text(day.name)
                .font(.system(size: large ? 13 : 11, weight: .semibold, design: .rounded))
                .foregroundColor(day.isToday ? .white : .secondary)
            
            Text("\(day.date)")
                .font(.system(size: large ? 18 : 16, weight: .bold, design: .rounded))
                .foregroundColor(day.isToday ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: large ? 70 : 60)
        .background(
            ZStack {
                if day.isToday {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        )
    }
}

struct StatusCard: View {
    let icon: String
    let title: String
    let status: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? color.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? color : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Text(status)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.98))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: "group.com.yourcompany.calendar") ?? .standard
    }
}
