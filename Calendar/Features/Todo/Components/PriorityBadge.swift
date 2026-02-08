import SwiftUI

struct PriorityBadge: View {
  let priority: Priority

  var body: some View {
    Text(priority.displayName)
      .font(.system(size: 10, weight: .semibold))
      .foregroundColor(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color)
      .clipShape(Capsule())
  }

  var color: Color {
    switch priority {
    case .high: return .priorityHigh
    case .medium: return .priorityMedium
    case .low: return .priorityLow
    }
  }
}
