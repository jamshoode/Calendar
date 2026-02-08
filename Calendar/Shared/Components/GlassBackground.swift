import SwiftUI

// MARK: - CardStyle
// Flat solid surfaces using system-adaptive colors — no glass/material

struct CardStyle: ViewModifier {
  let cornerRadius: CGFloat
  let filled: Bool

  init(cornerRadius: CGFloat = Spacing.cardRadius, filled: Bool = true) {
    self.cornerRadius = cornerRadius
    self.filled = filled
  }

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(filled ? Color.surfaceCard : Color.clear)
      )
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.border, lineWidth: 0.5)
      )
  }
}

extension View {
  func cardStyle(cornerRadius: CGFloat = Spacing.cardRadius, filled: Bool = true) -> some View {
    modifier(CardStyle(cornerRadius: cornerRadius, filled: filled))
  }

  /// Legacy bridge — maps old glassBackground calls to new cardStyle
  func glassBackground(cornerRadius: CGFloat = Spacing.cardRadius, material: Material = .thin)
    -> some View
  {
    modifier(CardStyle(cornerRadius: cornerRadius))
  }
}

