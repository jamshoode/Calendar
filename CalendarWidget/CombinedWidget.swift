import SwiftUI
import WidgetKit

// MARK: - Combined Widget Data Model

struct CombinedEntry: TimelineEntry {
    let date: Date
    // Weather data
    let weatherIcon: String
    let currentTemp: Double
    let minTemp: Double
    let maxTemp: Double
    let city: String?
    let forecastDays: [ForecastDayInfo]
    // Calendar data  
    let thisWeek: [DayInfo]
    let nextWeek: [DayInfo]
    let hasTimer: Bool
    let hasAlarm: Bool
    let timerEndTime: Date?
    let timerRemainingTime: TimeInterval
    let isTimerPaused: Bool
    let isStopwatch: Bool
    let stopwatchStartTime: Date?
    let todoCount: Int
    let forcedColorScheme: String?
}

// MARK: - Combined Provider

struct CombinedProvider: TimelineProvider {
    func placeholder(in context: Context) -> CombinedEntry {
        let (thisWeek, nextWeek) = Self.getTwoWeeks(for: Date(), events: [:])
        return CombinedEntry(
            date: Date(),
            weatherIcon: "sun.max.fill",
            currentTemp: 18,
            minTemp: 12,
            maxTemp: 24,
            city: "Kyiv",
            forecastDays: placeholderForecastDays(),
            thisWeek: thisWeek,
            nextWeek: nextWeek,
            hasTimer: false,
            hasAlarm: false,
            timerEndTime: nil,
            timerRemainingTime: 0,
            isTimerPaused: false,
            isStopwatch: false,
            stopwatchStartTime: nil,
            todoCount: 0,
            forcedColorScheme: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CombinedEntry) -> Void) {
        let entry = createEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CombinedEntry>) -> Void) {
        var entries: [CombinedEntry] = []
        let currentDate = Date()
        
        // Generate entries every hour for 24 hours
        for offset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: offset, to: currentDate)!
            let entry = createEntry(for: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func createEntry(for date: Date) -> CombinedEntry {
        let defaults = UserDefaults.shared
        let forcedScheme = defaults.string(forKey: "debug_themeOverride")
        
        // Read weather data
        let weatherData = loadWeatherData(from: defaults)
        let weatherHistory = loadWeatherHistory(from: defaults)
        
        // Read calendar data
        let events = Self.decodeEventData(defaults.string(forKey: "widgetEventData"))
        let (thisWeek, nextWeek) = Self.getTwoWeeks(for: date, events: events)
        
        // Build forecast days
        let forecastDays = buildForecastDays(from: weatherData, history: weatherHistory, events: events)
        
        // Get current weather
        let currentWeather = getCurrentWeather(from: weatherData, for: date)
        
        // Get timer/alarm/todo data
        let timerIds = ["default", "countdown", "pomodoro"]
        var activeTimerId: String?
        for id in timerIds {
            if defaults.bool(forKey: "widget_\(id)_hasTimer") {
                activeTimerId = id
                break
            }
        }
        
        let hasTimer = activeTimerId != nil
        let isTimerPaused = defaults.bool(forKey: "widget_\(activeTimerId ?? "default")_isPaused")
        let isStopwatch = defaults.bool(forKey: "widget_\(activeTimerId ?? "default")_isStopwatch")
        let timerEndTime = defaults.object(forKey: "widget_\(activeTimerId ?? "default")_timerEnd") as? Date
        let stopwatchStartTime = defaults.object(forKey: "widget_\(activeTimerId ?? "default")_stopwatchStart") as? Date
        let timerRemainingTime = timerEndTime?.timeIntervalSince(date) ?? 0
        
        let hasAlarm = defaults.bool(forKey: "widget_hasAlarm")
        let todoCount = defaults.integer(forKey: "incompleteTodoCount")
        
        return CombinedEntry(
            date: date,
            weatherIcon: currentWeather.icon,
            currentTemp: currentWeather.temp,
            minTemp: currentWeather.minTemp,
            maxTemp: currentWeather.maxTemp,
            city: weatherData?.city,
            forecastDays: forecastDays,
            thisWeek: thisWeek,
            nextWeek: nextWeek,
            hasTimer: hasTimer,
            hasAlarm: hasAlarm,
            timerEndTime: timerEndTime,
            timerRemainingTime: timerRemainingTime,
            isTimerPaused: isTimerPaused,
            isStopwatch: isStopwatch,
            stopwatchStartTime: stopwatchStartTime,
            todoCount: todoCount,
            forcedColorScheme: forcedScheme
        )
    }

    // MARK: - Helper Methods
    
    private func loadWeatherData(from defaults: UserDefaults) -> WeatherData? {
        guard let data = defaults.data(forKey: "widgetWeatherData") else { return nil }
        do {
            return try JSONDecoder().decode(WeatherData.self, from: data)
        } catch {
            return nil
        }
    }
    
    private func loadWeatherHistory(from defaults: UserDefaults) -> WeatherHistory? {
        guard let data = defaults.data(forKey: "widgetWeatherHistory") else { return nil }
        do {
            return try JSONDecoder().decode(WeatherHistory.self, from: data)
        } catch {
            return nil
        }
    }

    private func buildForecastDays(from weatherData: WeatherData?, history: WeatherHistory?, events: [String: [String]]) -> [ForecastDayInfo] {
        let calendar = Calendar.current
        let today = Date()

        // Calculate Monday of current week
        let weekday = calendar.component(.weekday, from: today)
        let adjustedWeekday = (weekday + 5) % 7
        let mondayOfThisWeek = calendar.date(byAdding: .day, value: -adjustedWeekday, to: today)!
        
        let formatter = DateFormatter()
        formatter.locale = WidgetLocalization.locale
        let dayNames = formatter.shortStandaloneWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let orderedNames = Array(dayNames.dropFirst()) + [dayNames.first!]
        
        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.dateFormat = "yyyy-MM-dd"
        
        var forecastDays: [ForecastDayInfo] = []
        
        // Build 7 days starting from Monday
        for i in 0..<7 {
            let dayDate = calendar.date(byAdding: .day, value: i, to: mondayOfThisWeek)!
            let dayOfMonth = calendar.component(.day, from: dayDate)
            let isToday = calendar.isDate(dayDate, inSameDayAs: today)
            let key = dateKeyFormatter.string(from: dayDate)
            let colors = events[key] ?? []
            
            // Find matching forecast data
            let (icon, minTemp, maxTemp) = findForecastInHistory(dayDate, history: history, currentData: weatherData, calendar: calendar)
            
            let info = ForecastDayInfo(
                name: orderedNames[i % 7].prefix(3).uppercased(),
                date: dayOfMonth,
                fullDate: dayDate,
                weatherIcon: icon,
                minTemp: minTemp,
                maxTemp: maxTemp,
                isToday: isToday,
                isWeekend: i >= 5,
                eventColors: colors
            )
            forecastDays.append(info)
        }
        
        return forecastDays
    }
    
    private func findForecastInHistory(_ date: Date, history: WeatherHistory?, currentData: WeatherData?, calendar: Calendar) -> (icon: String, minTemp: Double, maxTemp: Double) {
        let normalizedTarget = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        // First check history (for past days)
        if let history = history, let entry = history.entry(for: normalizedTarget) {
            return (entry.code.icon(isDay: true), entry.minTemp, entry.maxTemp)
        }
        
        // Then check current forecast data (for today and future)
        if let currentData = currentData {
            for dailyPoint in currentData.dailyForecast {
                let normalizedPoint = calendar.startOfDay(for: dailyPoint.time)
                if normalizedTarget == normalizedPoint {
                    return (dailyPoint.code.icon(isDay: true), dailyPoint.minTemp, dailyPoint.maxTemp)
                }
            }
        }
        
        return ("questionmark.circle", 0, 0)
    }

    private func getCurrentWeather(from weatherData: WeatherData?, for date: Date) -> (icon: String, temp: Double, minTemp: Double, maxTemp: Double, isDay: Bool) {
        guard let weatherData = weatherData else {
            return ("sun.max.fill", 18, 12, 24, true)
        }

        let calendar = Calendar.current

        // Get current hourly point
        if let current = weatherData.hourlyForecast.first(where: { $0.time > date }) ?? weatherData.hourlyForecast.first {
            let daily = weatherData.dailyForecast.first(where: { calendar.isDate($0.time, inSameDayAs: current.time) })
            return (
                current.code.icon(isDay: current.isDay),
                current.temperature,
                daily?.minTemp ?? current.temperature - 5,
                daily?.maxTemp ?? current.temperature + 5,
                current.isDay
            )
        }

        // Fallback to first daily
        if let firstDaily = weatherData.dailyForecast.first {
            return (firstDaily.code.icon(isDay: true), (firstDaily.minTemp + firstDaily.maxTemp) / 2, firstDaily.minTemp, firstDaily.maxTemp, true)
        }

        return ("sun.max.fill", 18, 12, 24, true)
    }

    static func getTwoWeeks(for date: Date, events: [String: [String]]) -> ([DayInfo], [DayInfo]) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let adjustedWeekday = (weekday + 5) % 7
        let mondayOfThisWeek = calendar.date(byAdding: .day, value: -adjustedWeekday, to: date)!

        let formatter = DateFormatter()
        formatter.locale = WidgetLocalization.locale
        let dayNames = formatter.shortStandaloneWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let orderedNames = Array(dayNames.dropFirst()) + [dayNames.first!]

        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.dateFormat = "yyyy-MM-dd"

        var thisWeek: [DayInfo] = []
        var nextWeek: [DayInfo] = []

        for i in 0..<14 {
            let dayDate = calendar.date(byAdding: .day, value: i, to: mondayOfThisWeek)!
            let dayOfMonth = calendar.component(.day, from: dayDate)
            let isToday = calendar.isDate(dayDate, inSameDayAs: date)
            let key = dateKeyFormatter.string(from: dayDate)
            let colors = events[key] ?? []

            let info = DayInfo(
                name: orderedNames[i % 7],
                date: dayOfMonth,
                fullDate: dayDate,
                isToday: isToday,
                isWeekend: (i % 7) >= 5,
                eventColors: colors
            )

            if i < 7 {
                thisWeek.append(info)
            } else {
                nextWeek.append(info)
            }
        }

        return (thisWeek, nextWeek)
    }

    static func decodeEventData(_ jsonString: String?) -> [String: [String]] {
        guard let jsonString = jsonString,
              let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: [String]]
        else { return [:] }
        return dict
    }

    private func placeholderForecastDays() -> [ForecastDayInfo] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = WidgetLocalization.locale
        let dayNames = formatter.shortStandaloneWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: i, to: Date())!
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            return ForecastDayInfo(
                name: dayNames[weekdayIndex],
                date: calendar.component(.day, from: date),
                fullDate: date,
                weatherIcon: "sun.max.fill",
                minTemp: 15 + Double(i),
                maxTemp: 25 + Double(i),
                isToday: i == 0,
                isWeekend: (weekdayIndex == 0 || weekdayIndex == 6),
                eventColors: []
            )
        }
    }
}

// MARK: - Combined Widget

struct CombinedWidget: Widget {
    let kind: String = "CombinedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CombinedProvider()) { entry in
            CombinedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(WidgetLocalization.string(.combined))
        .description(WidgetLocalization.string(.combinedWidgetDescription))
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Entry View

struct CombinedWidgetEntryView: View {
    var entry: CombinedProvider.Entry
    @Environment(\.colorScheme) var systemColorScheme

    private var scheme: WidgetColorScheme {
        WidgetColorScheme.from(forcedColorScheme: entry.forcedColorScheme, environment: systemColorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top: Weather section + Status icons
            HStack {
                // Weather info
                HStack(spacing: 8) {
                    Image(systemName: entry.weatherIcon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(scheme.accent)
                        .symbolRenderingMode(.multicolor)

                    Text("\(Int(entry.currentTemp))°")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(scheme.textPrimary)
                }

                Spacer()

                // Min/Max temps
                VStack(alignment: .trailing, spacing: 4) {
                    Spacer()
                    
                    Text("\(Int(entry.minTemp))° / \(Int(entry.maxTemp))°")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(scheme.textSecondary)

                    if let city = entry.city {
                        Text(city)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(scheme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }

                Spacer()

                // Status icons (Timer, Alarm, Todo)
                HStack(spacing: 12) {
                    // Timer
                    if entry.hasTimer || entry.isStopwatch {
                        TimerIcon(entry: entry, scheme: scheme)
                    }
                    
                    // Alarm
                    if entry.hasAlarm {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 18))
                            .foregroundColor(scheme.accent)
                    }
                    
                    // Todo count
                    if entry.todoCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(scheme.accent)
                            Text("\(entry.todoCount)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(scheme.textPrimary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(scheme.surface)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Divider
            Rectangle()
                .fill(scheme.divider)
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            Spacer(minLength: 8)

            // Middle: Weather forecast strip
            HStack(spacing: 8) {
                ForEach(entry.forecastDays) { day in
                    CombinedForecastDayColumn(day: day, scheme: scheme)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Divider
            Rectangle()
                .fill(scheme.divider)
                .frame(height: 0.5)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            Spacer(minLength: 8)

            // Bottom: Two weeks calendar
            VStack(spacing: 8) {
                // This week
                CombinedWeekRow(week: entry.thisWeek, scheme: scheme)
                
                // Next week
                CombinedWeekRow(week: entry.nextWeek, scheme: scheme)
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 8)
        }
        .containerBackground(for: .widget) {
            widgetGradientBackground(scheme: scheme)
        }
    }
}

// MARK: - Subviews

struct CombinedForecastDayColumn: View {
    let day: ForecastDayInfo
    let scheme: WidgetColorScheme

    var body: some View {
        VStack(spacing: 4) {
            // Day name
            Text(day.name.prefix(3).uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(
                    day.isToday
                        ? scheme.accent
                        : day.isWeekend
                            ? scheme.textSecondary
                            : scheme.textPrimary
                )

            // Weather icon
            Image(systemName: day.weatherIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(scheme.accent)
                .symbolRenderingMode(.multicolor)

            // Min/Max temps
            VStack(spacing: 2) {
                Text("\(Int(day.maxTemp))°")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(scheme.textPrimary)
                Text("\(Int(day.minTemp))°")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(scheme.textSecondary)
            }

            // Day number with today highlight
            ZStack {
                if day.isToday {
                    Circle()
                        .fill(scheme.todayHighlight)
                        .frame(width: 22, height: 22)
                }

                if !day.eventColors.isEmpty {
                    DayEventRing(eventColors: day.eventColors, scheme: scheme, size: 24)
                }

                Text("\(day.date)")
                    .font(.system(size: 11, weight: day.isToday ? .bold : .semibold, design: .rounded))
                    .foregroundColor(day.isToday ? .white : scheme.textPrimary)
            }
            .frame(width: 26, height: 26)
        }
        .padding(.vertical, 4)
    }
}

struct CombinedWeekRow: View {
    let week: [DayInfo]
    let scheme: WidgetColorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(week) { day in
                CombinedDayCell(day: day, scheme: scheme)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct CombinedDayCell: View {
    let day: DayInfo
    let scheme: WidgetColorScheme

    var body: some View {
        VStack(spacing: 4) {
            // Day name
            Text(day.name.prefix(3).uppercased())
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(
                    day.isToday
                        ? scheme.accent
                        : day.isWeekend
                            ? scheme.textSecondary
                            : scheme.textPrimary
                )

            // Day number with rings
            ZStack {
                if day.isToday {
                    Circle()
                        .fill(scheme.todayHighlight)
                        .frame(width: 20, height: 20)
                }

                if !day.eventColors.isEmpty {
                    DayEventRing(eventColors: day.eventColors, scheme: scheme, size: 22)
                }

                Text("\(day.date)")
                    .font(.system(size: 10, weight: day.isToday ? .bold : .semibold, design: .rounded))
                    .foregroundColor(day.isToday ? .white : scheme.textPrimary)
            }
            .frame(width: 24, height: 24)
        }
        .padding(.vertical, 2)
    }
}

struct TimerIcon: View {
    let entry: CombinedEntry
    let scheme: WidgetColorScheme

    var body: some View {
        let isActive = entry.timerRemainingTime > 0 && !entry.isTimerPaused
        let isPaused = entry.isTimerPaused
        
        ZStack {
            Circle()
                .fill(isActive ? scheme.accent.opacity(0.2) : scheme.surface)
                .frame(width: 32, height: 32)
            
            Image(systemName: entry.isStopwatch ? "stopwatch.fill" : "timer")
                .font(.system(size: 16))
                .foregroundColor(isActive ? scheme.accent : isPaused ? .orange : scheme.textSecondary)
        }
    }
}
