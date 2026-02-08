import SwiftUI

struct GlassButton: View {
  let title: String
  let icon: String?
  let action: () -> Void
  let isPrimary: Bool

  init(title: String, icon: String? = nil, isPrimary: Bool = false, action: @escaping () -> Void) {
    self.title = title
    self.icon = icon
    self.isPrimary = isPrimary
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      content
    }
    .buttonStyle(.plain)
  }

  private var content: some View {
    HStack(spacing: Spacing.xs) {
      if let icon = icon {
        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
      }
      Text(title)
        .font(Typography.headline)
    }
    .padding(.horizontal, Spacing.lg)
    .padding(.vertical, Spacing.sm)
    .foregroundColor(isPrimary ? .white : .textPrimary)
    .background(backgroundView)
    .overlay(
      RoundedRectangle(cornerRadius: Spacing.smallRadius)
        .stroke(Color.border, lineWidth: 0.5)
    )
  }

  @ViewBuilder
  private var backgroundView: some View {
    if isPrimary {
      Color.accentColor
        .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
    } else {
      RoundedRectangle(cornerRadius: Spacing.smallRadius)
        .fill(Color.secondaryFill)
    }
  }
}
