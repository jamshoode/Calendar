import SwiftUI

struct GlassCard<Content: View>: View {
  let content: Content
  let cornerRadius: CGFloat

  init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
    self.cornerRadius = cornerRadius
    self.content = content()
  }

  var body: some View {
    content
      .padding()
      .background(.thinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
      )
  }
}
