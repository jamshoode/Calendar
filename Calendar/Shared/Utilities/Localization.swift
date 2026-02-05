import Foundation

struct Localization {
    enum Language {
        case ukrainian
        case english
    }

    static var currentLanguage: Language {
        // Retrieve the user's preferred language order
        let preferred = Locale.preferredLanguages.first ?? "en"
        
        // "uk" is Ukrainian. It might appear as "uk-UA", "uk-US", "uk" etc.
        if preferred.starts(with: "uk") {
            return .ukrainian
        }
        
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        return langCode == "uk" ? .ukrainian : .english
    }
    
    static var locale: Locale {
        return currentLanguage == .ukrainian ? Locale(identifier: "uk_UA") : Locale(identifier: "en_US")
    }

    enum Key {
        // Common
        case save
        case cancel
        case update
        case delete
        
        // Calendar / Event List
        case selectDate
        case eventsCount(Int)
        case noEvents
        case tapToAdd
        case addEvent
        
        // Add/Edit Event
        case newEvent
        case editEvent
        case title
        case eventTitlePlaceholder
        case notes
        case notesPlaceholder
        case color
        case date
        case reminder
        case none
        case atTimeOfEvent
        case minutesBefore(Int)
        case hoursBefore(Int)
        case dayBefore // 1 day
        case daysBefore(Int)
        
        // Widget / Timer / Alarm
        case active
        case idle
        case alarm
        case timer
        case set
        case off
        case status
        
        // Accessibility / Navigation
        case previousMonth
        case nextMonth
        case calendarFor(String)
        
        // Tabs
        case tabCalendar
        case tabTimer
        case tabAlarm
        
        // Alarm View
        case noAlarmSet
        case tapToSetAlarm
        case setAlarm
        case edit
        // .delete already exists
        

        // Time Picker / Timer Views
        case timePicker
        case alarmWillRingAt(String)
        case alarmSetFor(String)
        case countdown
        case pomodoro
        case selectTimerType
        case pomodoroSession(Int, Int)
        case timeRemaining(String)
        case alarmTime(String)
        
        // General / Errors
        case pageNotFound
        case selectTabPrompt

        // Weekdays (Manual if needed, or use Locale)
        // We will often use DateFormatter with .locale, but for explicit UI labels:
        case mon, tue, wed, thu, fri, sat, sun
    }
    
    static func string(_ key: Key) -> String {
        let lang = currentLanguage
        
        switch key {
        // Common
        case .save:
            return lang == .ukrainian ? "Зберегти" : "Save"
        case .cancel:
            return lang == .ukrainian ? "Скасувати" : "Cancel"
        case .update:
            return lang == .ukrainian ? "Оновити" : "Update"
        case .delete:
            return lang == .ukrainian ? "Видалити" : "Delete"
            
        // Calendar
        case .selectDate:
            return lang == .ukrainian ? "Оберіть дату" : "Select a date"
        case .eventsCount(let count):
            if lang == .ukrainian {
                // Simple pluralization for UA (can be complex, simplification: "X подій")
                return "\(count) подій"
            } else {
                return "\(count) event\(count == 1 ? "" : "s")"
            }
        case .noEvents:
            return lang == .ukrainian ? "Немає подій" : "No events"
        case .tapToAdd:
            return lang == .ukrainian ? "Натисніть, щоб додати" : "Tap to add"
        case .addEvent:
            return lang == .ukrainian ? "Додати подію" : "Add event"
            
        // Add/Edit
        case .newEvent:
            return lang == .ukrainian ? "Нова подія" : "New Event"
        case .editEvent:
            return lang == .ukrainian ? "Редагувати подію" : "Edit Event"
        case .title:
            return lang == .ukrainian ? "Назва" : "Title"
        case .eventTitlePlaceholder:
            return lang == .ukrainian ? "Назва події" : "Event Title"
        case .notes:
            return lang == .ukrainian ? "Нотатки" : "Notes"
        case .notesPlaceholder:
            return lang == .ukrainian ? "Додати нотатки..." : "Add notes..."
        case .color:
            return lang == .ukrainian ? "Колір" : "Color"
        case .date:
            return lang == .ukrainian ? "Дата" : "Date"
        case .reminder:
            return lang == .ukrainian ? "Нагадування" : "Reminder"
        case .none:
            return lang == .ukrainian ? "Немає" : "None"
        case .atTimeOfEvent:
            return lang == .ukrainian ? "Під час події" : "At time of event"
        case .minutesBefore(let min):
            return lang == .ukrainian ? "\(min) хв до" : "\(min) mins before"
        case .hoursBefore(let hours):
            return lang == .ukrainian ? "\(hours) год до" : "\(hours) hours before"
        case .dayBefore:
            return lang == .ukrainian ? "1 день до" : "1 day before"
        case .daysBefore(let days):
            return lang == .ukrainian ? "\(days) днів до" : "\(days) days before"
            
        // Widget
        case .active:
            return lang == .ukrainian ? "Активний" : "Active"
        case .idle:
            return lang == .ukrainian ? "Очікування" : "Idle"
        case .alarm:
            return lang == .ukrainian ? "Будильник" : "Alarm"
        case .timer:
            return lang == .ukrainian ? "Таймер" : "Timer"
        case .set:
            return lang == .ukrainian ? "Встановлено" : "Set"
        case .off:
            return lang == .ukrainian ? "Вимк" : "Off"
        case .status:
            return lang == .ukrainian ? "Статус" : "Status"
            
        // Accessibility / Navigation
        case .previousMonth:
            return lang == .ukrainian ? "Попередній місяць" : "Previous month"
        case .nextMonth:
            return lang == .ukrainian ? "Наступний місяць" : "Next month"
        case .calendarFor(let dateString):
            return lang == .ukrainian ? "Календар на \(dateString)" : "Calendar for \(dateString)"
            
        // Tabs
        case .tabCalendar:
            return lang == .ukrainian ? "Календар" : "Calendar"
        case .tabTimer:
            return lang == .ukrainian ? "Таймер" : "Timer"
        case .tabAlarm:
            return lang == .ukrainian ? "Будильник" : "Alarm"
            
        // Alarm View
        case .noAlarmSet:
            return lang == .ukrainian ? "Будильник не встановлено" : "No Alarm Set"
        case .tapToSetAlarm:
            return lang == .ukrainian ? "Натисніть кнопку нижче, щоб встановити будильник" : "Tap the button below to set an alarm"
        case .setAlarm:
            return lang == .ukrainian ? "Встановити будильник" : "Set Alarm"
        case .edit:
            return lang == .ukrainian ? "Редагувати" : "Edit"
            
        // Weekdays
        case .mon: return "Mon" // Usually formatted by DateFormatter
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        case .sun: return "Sun"
            
        // Time Picker / Timer
        case .timePicker:
            return lang == .ukrainian ? "Вибір часу" : "Time picker"
        case .alarmWillRingAt(let time):
            return lang == .ukrainian ? "Будильник продзвенить о \(time)" : "Alarm will ring at \(time)"
        case .alarmSetFor(let time):
            return lang == .ukrainian ? "Будильник встановлено на \(time)" : "Alarm set for \(time)"
        case .countdown:
            return lang == .ukrainian ? "Зворотній відлік" : "Countdown"
        case .pomodoro:
            return lang == .ukrainian ? "Помодоро" : "Pomodoro"
        case .selectTimerType:
            return lang == .ukrainian ? "Оберіть тип таймера" : "Select timer type"
        case .pomodoroSession(let current, let total):
            return lang == .ukrainian ? "Сесія \(current) з \(total)" : "Session \(current) of \(total)"
        case .timeRemaining(let time):
            return lang == .ukrainian ? "Залишилось часу: \(time)" : "Time remaining: \(time)"
        case .alarmTime(let time):
            return lang == .ukrainian ? "Час будильника: \(time)" : "Alarm time: \(time)"
            
        // General
        case .pageNotFound:
            return lang == .ukrainian ? "Сторінку не знайдено" : "Page Not Found"
        case .selectTabPrompt:
            return lang == .ukrainian ? "Будь ласка, оберіть вкладку на бічній панелі" : "Please select a tab from the sidebar"
        }
    }
}
