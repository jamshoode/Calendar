import SwiftUI

struct PriorityBadge: View {
  let priority: Priority

  var body: some View {
    Text(priority.displayName.uppercased())
      .font(.system(size: 9, weight: .bold))
      .foregroundColor(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(
        LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
      )
      .clipShape(Capsule())
      .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
  }

  var color: Color {
    switch priority {
    case .high: return .priorityHigh
    case .medium: return .priorityMedium
    case .low: return .priorityLow
    }
  }
}
