import SwiftUI

struct TodoCheckbox: View {
  let isCompleted: Bool
  let priority: Priority
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .stroke(priorityColor, lineWidth: 2)
          .frame(width: 24, height: 24)

        if isCompleted {
          Circle()
            .fill(priorityColor)
            .frame(width: 24, height: 24)

          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
        }
      }
    }
    .buttonStyle(.plain)
  }

  private var priorityColor: Color {
    switch priority {
    case .high: return .red
    case .medium: return .orange
    case .low: return .blue
    }
  }
}
