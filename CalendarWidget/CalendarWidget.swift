import WidgetKit
import SwiftUI
import UIKit

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
    let timerEndTime: Date?
    let timerRemainingTime: TimeInterval
    let isTimerPaused: Bool
    let isStopwatch: Bool
    let stopwatchStartTime: Date?
}

struct WeekDay: Identifiable {
    let id = UUID()
    let name: String
    let date: Int
    let isToday: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(
            date: Date(),
            weekDays: sampleWeekDays(),
            hasTimer: false,
            hasAlarm: false,
            timerEndTime: nil,
            timerRemainingTime: 0,
            isTimerPaused: false,
            isStopwatch: false,
            stopwatchStartTime: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let entry = CalendarEntry(
            date: Date(),
            weekDays: sampleWeekDays(),
            hasTimer: false,
            hasAlarm: false,
            timerEndTime: nil,
            timerRemainingTime: 0,
            isTimerPaused: false,
            isStopwatch: false,
            stopwatchStartTime: nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [CalendarEntry] = []
        let currentDate = Date()
        
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let defaults = UserDefaults.shared
            let timerIds = ["countdown", "pomodoro"]
            
            var activeTimerId: String?
            for id in timerIds {
                if defaults.bool(forKey: "\(id).isRunning") || defaults.bool(forKey: "\(id).isPaused") {
                    activeTimerId = id
                    break
                }
            }
            
            let timerId = activeTimerId ?? "countdown"
            
            // Legacy fallback check
            let globalHasTimer = defaults.bool(forKey: "hasActiveTimer")
            
            let isRunning = defaults.bool(forKey: "\(timerId).isRunning")
            let isPaused = defaults.bool(forKey: "\(timerId).isPaused")
            let isStopwatch = defaults.bool(forKey: "\(timerId).isStopwatch")
            let remainingTime = defaults.double(forKey: "\(timerId).remainingTime")
            let endTime = defaults.object(forKey: "\(timerId).endTime") as? Date
            let startTime = defaults.object(forKey: "\(timerId).startTime") as? Date
            
            let entry = CalendarEntry(
                date: entryDate,
                weekDays: getWeekDays(for: entryDate),
                hasTimer: isRunning || isPaused || isStopwatch || globalHasTimer,
                hasAlarm: defaults.bool(forKey: "hasActiveAlarm"),
                timerEndTime: endTime,
                timerRemainingTime: remainingTime,
                isTimerPaused: isPaused,
                isStopwatch: isStopwatch,
                stopwatchStartTime: startTime
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

        let formatter = DateFormatter()
        formatter.locale = WidgetLocalization.locale
        let dayNames = formatter.shortStandaloneWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] // Fallback
        // shortStandaloneWeekdaySymbols usually starts Sunday (index 0). 
        // Our logic loop i in 0..<7. 
        // We need to map i (0=Mon?) to correct symbol.
        // My previous logic: dayNames[i] where i=0 was Mon.
        // Standard symbols: 0=Sun, 1=Mon.
        // So dayNames is Sun, Mon, Tue...
        // If i=0 (Mon), I need index 1.
        // Adjusted:
        let orderedNames = Array(dayNames.dropFirst()) + [dayNames.first!] // Shift Sun to end -> Mon...Sun
        
        for i in 0..<7 {
            let dayDate = calendar.date(byAdding: .day, value: i - adjustedWeekday, to: date)!
            let dayOfMonth = calendar.component(.day, from: dayDate)
            let isToday = calendar.isDate(dayDate, inSameDayAs: date)
            
            weekDays.append(WeekDay(
                name: orderedNames[i],
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
                    Text(entry.date.formatted(.dateTime.weekday(.wide).locale(WidgetLocalization.locale)))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(entry.date.formatted(.dateTime.month().day().locale(WidgetLocalization.locale)))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 12)
            } else {
                HStack(spacing: 12) {
                    if entry.hasTimer {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            if entry.isTimerPaused {
                                Text(formatDuration(entry.timerRemainingTime))
                            } else if entry.isStopwatch, let startTime = entry.stopwatchStartTime {
                                Text(startTime, style: .timer)
                            } else if let endTime = entry.timerEndTime {
                                Text(endTime, style: .timer)
                            } else {
                                Text(WidgetLocalization.string(.active))
                            }
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.accentColor))
                    }
                    
                    if entry.hasAlarm {
                        Label(WidgetLocalization.string(.alarm), systemImage: "alarm.fill")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.orange))
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
        .containerBackground(for: .widget) {
            Color(UIColor { trait in
                trait.userInterfaceStyle == .dark ? .black : .white
            })
        }
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
                Text(WidgetLocalization.string(.status))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    StatusCard(
                        icon: "timer",
                        title: WidgetLocalization.string(.timer),
                        statusText: timerStatusText(entry: entry),
                        color: .accentColor,
                        isActive: entry.hasTimer
                    )
                    
                    StatusCard(
                        icon: "alarm.fill",
                        title: WidgetLocalization.string(.alarm),
                        status: entry.hasAlarm ? WidgetLocalization.string(.set) : WidgetLocalization.string(.off),
                        color: .orange,
                        isActive: entry.hasAlarm
                    )
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(UIColor { trait in
                trait.userInterfaceStyle == .dark ? .black : .white
            })
        }
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
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        )
    }
}

struct StatusCard: View {
    let icon: String
    let title: String
    let statusText: Text
    let color: Color
    let isActive: Bool
    
    init(icon: String, title: String, statusText: Text? = nil, status: String? = nil, color: Color, isActive: Bool) {
        self.icon = icon
        self.title = title
        if let statusText = statusText {
            self.statusText = statusText
        } else {
            self.statusText = Text(status ?? "")
        }
        self.color = color
        self.isActive = isActive
    }
    
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
                statusText
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

func timerStatusText(entry: CalendarEntry) -> Text {
    if entry.hasTimer {
        if entry.isTimerPaused {
            return Text(formatDuration(entry.timerRemainingTime))
        } else if entry.isStopwatch, let startTime = entry.stopwatchStartTime {
            return Text(startTime, style: .timer)
        } else if let endTime = entry.timerEndTime {
            return Text(endTime, style: .timer)
        } else {
            return Text(WidgetLocalization.string(.active))
        }
    } else {
        return Text(WidgetLocalization.string(.idle))
    }
}

func formatDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: "group.com.shoode.calendar") ?? .standard
    }
}
