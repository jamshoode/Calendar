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
    HStack(spacing: 8) {
      if let icon = icon {
        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
      }
      Text(title)
        .font(.system(size: 16, weight: .semibold))
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .foregroundColor(isPrimary ? .white : .primary)
    .background(backgroundView)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
    )
  }

  @ViewBuilder
  private var backgroundView: some View {
    if isPrimary {
      Color.accentColor
        .clipShape(RoundedRectangle(cornerRadius: 12))
    } else {
      RoundedRectangle(cornerRadius: 12)
        .fill(.thinMaterial)
    }
  }
}
