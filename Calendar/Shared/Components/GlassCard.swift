import SwiftUI

struct GlassCard<Content: View>: View {
  let content: Content
  let cornerRadius: CGFloat

  init(cornerRadius: CGFloat = Spacing.cardRadius, @ViewBuilder content: () -> Content) {
    self.cornerRadius = cornerRadius
    self.content = content()
  }

  var body: some View {
    content
      .padding(Spacing.cardPadding)
      .background(Color.surfaceCard)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.border, lineWidth: 0.5)
      )
  }
}
