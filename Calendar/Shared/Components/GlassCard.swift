import SwiftUI

struct GlassCard<Content: View>: View {
  let content: Content
  let cornerRadius: CGFloat
  let material: MeshGradientMaterial

  enum MeshGradientMaterial {
      case ultraThin
      case thin
      case regular
      
      var systemMaterial: Material {
          switch self {
          case .ultraThin: return .ultraThin
          case .thin: return .thin
          case .regular: return .regular
          }
      }
  }

  init(
    cornerRadius: CGFloat = Spacing.cardRadius,
    material: MeshGradientMaterial = .thin,
    @ViewBuilder content: () -> Content
  ) {
    self.cornerRadius = cornerRadius
    self.material = material
    self.content = content()
  }

  var body: some View {
    content
      .padding(Spacing.cardPadding)
      .background(material.systemMaterial)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .glassHalo(cornerRadius: cornerRadius)
      .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
  }
}
