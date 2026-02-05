import SwiftUI

struct PriorityBadge: View {
  let priority: Priority

  var body: some View {
    Text(priority.displayName)
      .font(.system(size: 10, weight: .semibold))
      .foregroundColor(foregroundColor)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(backgroundColor)
      .clipShape(Capsule())
  }

  private var foregroundColor: Color {
    switch priority {
    case .high: return .white
    case .medium: return .white
    case .low: return .white
    }
  }

  private var backgroundColor: Color {
    switch priority {
    case .high: return .red
    case .medium: return .orange
    case .low: return .blue
    }
  }
}
