import SwiftUI

// MARK: - Design System Colors
// Monochromatic neutral chrome — color appears ONLY in content (events, statuses, categories)

extension Color {
  // MARK: Backgrounds
  /// Primary background — adapts to system light/dark
  static let backgroundPrimary = Color(UIColor.systemBackground)
  /// Secondary background — slightly elevated
  static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
  /// Grouped background — for grouped table/form views
  static let backgroundGrouped = Color(UIColor.systemGroupedBackground)

  // MARK: Surfaces
  /// Card surface — for elevated card containers
  static let surfaceCard = Color(UIColor.secondarySystemGroupedBackground)
  /// Elevated surface — for floating elements
  static let surfaceElevated = Color(UIColor.tertiarySystemBackground)

  // MARK: Text
  static let textPrimary = Color(UIColor.label)
  static let textSecondary = Color(UIColor.secondaryLabel)
  static let textTertiary = Color(UIColor.tertiaryLabel)

  // MARK: Chrome
  static let border = Color(UIColor.separator)
  static let divider = Color(UIColor.opaqueSeparator)
  static let fill = Color(UIColor.systemFill)
  static let secondaryFill = Color(UIColor.secondarySystemFill)
  static let tertiaryFill = Color(UIColor.tertiarySystemFill)
  static let separator = Color(UIColor.separator)

  // MARK: Overlays
  /// Scrim overlay for modals and sheets
  static let backgroundScrim = Color.black.opacity(0.3)
  /// Shadow color — adapts subtly
  static let shadowColor = Color.black.opacity(0.12)

  // MARK: Event Colors (the ONLY custom colors in the design system)
  static let eventBlue = Color.blue
  static let eventGreen = Color.green
  static let eventOrange = Color.orange
  static let eventRed = Color.red
  static let eventPurple = Color.purple
  static let eventPink = Color.pink
  static let eventYellow = Color.yellow
  static let eventTeal = Color(red: 50 / 255, green: 173 / 255, blue: 230 / 255)

  static func eventColor(named name: String) -> Color {
    switch name.lowercased() {
    case "blue": return .eventBlue
    case "green": return .eventGreen
    case "orange": return .eventOrange
    case "red": return .eventRed
    case "purple": return .eventPurple
    case "pink": return .eventPink
    case "yellow": return .eventYellow
    case "teal": return .eventTeal
    default: return .eventBlue
    }
  }

  // MARK: Status Badge Colors
  static let statusCompleted = Color.green
  static let statusInProgress = Color.orange
  static let statusQueued = Color(UIColor.systemGray)

  // MARK: Priority Colors (single source of truth)
  static let priorityHigh = Color.red
  static let priorityMedium = Color.orange
  static let priorityLow = Color.blue

  // MARK: Expense Category Colors
  static let expenseGroceries = Color(red: 76 / 255, green: 175 / 255, blue: 80 / 255)
  static let expenseHousing = Color(red: 66 / 255, green: 133 / 255, blue: 244 / 255)
  static let expenseTransport = Color(red: 255 / 255, green: 152 / 255, blue: 0 / 255)
  static let expenseSubscriptions = Color(red: 156 / 255, green: 39 / 255, blue: 176 / 255)
  static let expenseHealthcare = Color(red: 233 / 255, green: 30 / 255, blue: 99 / 255)
  static let expenseDebt = Color(red: 244 / 255, green: 67 / 255, blue: 54 / 255)
  static let expenseEntertainment = Color(red: 255 / 255, green: 193 / 255, blue: 7 / 255)
  static let expenseDining = Color(red: 121 / 255, green: 85 / 255, blue: 72 / 255)
  static let expenseShopping = Color(red: 0 / 255, green: 150 / 255, blue: 136 / 255)
  static let expenseOther = Color(UIColor.systemGray2)
}
