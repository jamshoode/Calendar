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
    case dayBefore  // 1 day
    case daysBefore(Int)
    case minutesShort(Int)
    case minutesUnit

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

    // Todo
    case tabTodo
    case addTodo
    case editTodo
    case todoTitle
    case addCategory
    case editCategory
    case categoryName
    case noCategory
    case category
    case priority
    case priorityHigh
    case priorityMedium
    case priorityLow
    case dueDate
    case hasDueDate
    case recurring
    case weekly
    case monthly
    case yearly
    case everyNWeeks(Int)
    case everyNMonths(Int)
    case everyNYears(Int)
    case endDate
    case subtasks
    case addSubtask
    case noTodos
    case tapToAddTodo
    case todosCount(Int)
    case completed

    // Sorting
    case sortBy
    case newestFirst
    case oldestFirst
    case manual

    // Pin
    case pin
    case unpin
    case pinned

    // Settings
    case settings
    case appInfo
    case version
    case build
    case mode
    case debugSettings
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
    case .minutesShort(let min):
      return lang == .ukrainian ? "\(min) хв" : "\(min) min"
    case .minutesUnit:
      return lang == .ukrainian ? "хв" : "min"

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
      return lang == .ukrainian
        ? "Натисніть кнопку нижче, щоб встановити будильник"
        : "Tap the button below to set an alarm"
    case .setAlarm:
      return lang == .ukrainian ? "Встановити будильник" : "Set Alarm"
    case .edit:
      return lang == .ukrainian ? "Редагувати" : "Edit"

    // Weekdays
    case .mon: return "Mon"  // Usually formatted by DateFormatter
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
      return lang == .ukrainian
        ? "Будь ласка, оберіть вкладку на бічній панелі" : "Please select a tab from the sidebar"

    // Todo
    case .tabTodo:
      return lang == .ukrainian ? "Завдання" : "Todo"
    case .addTodo:
      return lang == .ukrainian ? "Додати завдання" : "Add Todo"
    case .editTodo:
      return lang == .ukrainian ? "Редагувати завдання" : "Edit Todo"
    case .todoTitle:
      return lang == .ukrainian ? "Назва завдання" : "Todo Title"
    case .addCategory:
      return lang == .ukrainian ? "Додати категорію" : "Add Category"
    case .editCategory:
      return lang == .ukrainian ? "Редагувати категорію" : "Edit Category"
    case .categoryName:
      return lang == .ukrainian ? "Назва категорії" : "Category Name"
    case .noCategory:
      return lang == .ukrainian ? "Без категорії" : "No Category"
    case .category:
      return lang == .ukrainian ? "Категорія" : "Category"
    case .priority:
      return lang == .ukrainian ? "Пріоритет" : "Priority"
    case .priorityHigh:
      return lang == .ukrainian ? "Високий" : "High"
    case .priorityMedium:
      return lang == .ukrainian ? "Середній" : "Medium"
    case .priorityLow:
      return lang == .ukrainian ? "Низький" : "Low"
    case .dueDate:
      return lang == .ukrainian ? "Термін" : "Due Date"
    case .hasDueDate:
      return lang == .ukrainian ? "Встановити термін" : "Set Due Date"
    case .recurring:
      return lang == .ukrainian ? "Повторення" : "Recurring"
    case .weekly:
      return lang == .ukrainian ? "Щотижня" : "Weekly"
    case .monthly:
      return lang == .ukrainian ? "Щомісяця" : "Monthly"
    case .yearly:
      return lang == .ukrainian ? "Щороку" : "Yearly"
    case .everyNWeeks(let n):
      return lang == .ukrainian ? "Кожні \(n) тижнів" : "Every \(n) week\(n == 1 ? "" : "s")"
    case .everyNMonths(let n):
      return lang == .ukrainian ? "Кожні \(n) місяців" : "Every \(n) month\(n == 1 ? "" : "s")"
    case .everyNYears(let n):
      return lang == .ukrainian ? "Кожні \(n) років" : "Every \(n) year\(n == 1 ? "" : "s")"
    case .endDate:
      return lang == .ukrainian ? "Дата завершення" : "End Date"
    case .subtasks:
      return lang == .ukrainian ? "Підзавдання" : "Subtasks"
    case .addSubtask:
      return lang == .ukrainian ? "Додати підзавдання" : "Add Subtask"
    case .noTodos:
      return lang == .ukrainian ? "Немає завдань" : "No Todos"
    case .tapToAddTodo:
      return lang == .ukrainian ? "Натисніть, щоб додати завдання" : "Tap to add a todo"
    case .todosCount(let count):
      if lang == .ukrainian {
        return "\(count) завдань"
      } else {
        return "\(count) todo\(count == 1 ? "" : "s")"
      }
    case .completed:
      return lang == .ukrainian ? "виконано" : "completed"
    case .sortBy:
      return lang == .ukrainian ? "Сортувати" : "Sort by"
    case .newestFirst:
      return lang == .ukrainian ? "Спочатку нові" : "Newest first"
    case .oldestFirst:
      return lang == .ukrainian ? "Спочатку старі" : "Oldest first"
    case .manual:
      return lang == .ukrainian ? "Вручну" : "Manual"
    case .pin:
      return lang == .ukrainian ? "Закріпити" : "Pin"
    case .unpin:
      return lang == .ukrainian ? "Відкріпити" : "Unpin"
    case .pinned:
      return lang == .ukrainian ? "Закріплені" : "Pinned"
    case .settings:
      return lang == .ukrainian ? "Налаштування" : "Settings"
    case .appInfo:
      return lang == .ukrainian ? "Про додаток" : "App Info"
    case .version:
      return lang == .ukrainian ? "Версія" : "Version"
    case .build:
      return lang == .ukrainian ? "Збірка" : "Build"
    case .mode:
      return lang == .ukrainian ? "Режим" : "Mode"
    case .debugSettings:
      return lang == .ukrainian ? "Налаштування налагодження" : "Debug Settings"
    }
  }
}
