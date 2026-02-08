import SwiftUI

// MARK: - StatusBadge
// Reusable colored pill component for task statuses

struct StatusBadge: View {
  enum Status: String {
    case completed
    case inProgress
    case queued

    var displayName: String {
      switch self {
      case .completed: return Localization.string(.completed)
      case .inProgress: return Localization.string(.inProgress)
      case .queued: return Localization.string(.queued)
      }
    }

    var color: Color {
      switch self {
      case .completed: return .statusCompleted
      case .inProgress: return .statusInProgress
      case .queued: return .statusQueued
      }
    }

    var icon: String {
      switch self {
      case .completed: return "checkmark.circle.fill"
      case .inProgress: return "clock.fill"
      case .queued: return "circle"
      }
    }
  }

  let status: Status
  var showIcon: Bool = false

  var body: some View {
    HStack(spacing: 4) {
      if showIcon {
        Image(systemName: status.icon)
          .font(.system(size: 9, weight: .bold))
      }
      Text(status.displayName)
        .font(Typography.badge)
    }
    .foregroundColor(status.color)
    .padding(.horizontal, Spacing.xs)
    .padding(.vertical, Spacing.xxxs + 1)
    .background(status.color.opacity(0.12))
    .clipShape(Capsule())
  }
}
