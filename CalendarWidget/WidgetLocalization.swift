import Foundation

struct WidgetLocalization {
  enum Language {
    case ukrainian
    case english
  }

  static var currentLanguage: Language {
    let preferred = Locale.preferredLanguages.first ?? "en"
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
    case active
    case idle
    case alarm
    case timer
    case set
    case off
    case status
    case calendar
    case widgetDescription
    case todo
    case paused
    case stopwatch
    case weather
    case weatherWidgetDescription
    case combined
    case combinedWidgetDescription
  }

  static func string(_ key: Key) -> String {
    let lang = currentLanguage

    switch key {
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
    case .calendar:
      return lang == .ukrainian ? "Календар" : "Calendar"
    case .widgetDescription:
      return lang == .ukrainian
        ? "Показує поточний тиждень та статус таймера/будильника."
        : "Shows the current week and timer/alarm status."
    case .todo:
      return lang == .ukrainian ? "Завдання" : "Todo"
    case .paused:
      return lang == .ukrainian ? "Пауза" : "Paused"
    case .stopwatch:
      return lang == .ukrainian ? "Секундомір" : "Stopwatch"
    case .weather:
      return lang == .ukrainian ? "Погода" : "Weather"
    case .weatherWidgetDescription:
      return lang == .ukrainian
        ? "Показує погоду та календар на тиждень."
        : "Shows weather and weekly calendar."
    case .combined:
      return lang == .ukrainian ? "Погода та Календар" : "Weather & Calendar"
    case .combinedWidgetDescription:
      return lang == .ukrainian
        ? "Показує погоду, календар та статус таймера/будильника."
        : "Shows weather, calendar, and timer/alarm status."
    }
  }
}
