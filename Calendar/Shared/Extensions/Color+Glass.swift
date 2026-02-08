import SwiftUI

extension Color {
  static let glassBackground = Color.white.opacity(0.1)
  static let glassBorder = Color.white.opacity(0.2)
  static let glassHighlight = Color.white.opacity(0.3)

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
}
