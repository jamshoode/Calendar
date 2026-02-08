import SwiftUI

extension View {
  func glassEffect() -> some View {
    self
      .background(Color.surfaceCard)
      .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
      .overlay(
        RoundedRectangle(cornerRadius: Spacing.cardRadius)
          .stroke(Color.border, lineWidth: 0.5)
      )
  }

  func glassCard(padding: CGFloat = Spacing.cardPadding, cornerRadius: CGFloat = Spacing.cardRadius)
    -> some View
  {
    self
      .padding(padding)
      .glassEffect()
  }

  /// Conditionally apply a modifier only when the condition is true.
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
