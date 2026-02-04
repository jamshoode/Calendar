import SwiftUI

struct GlassBackground: ViewModifier {
    let cornerRadius: CGFloat
    let material: Material
    
    init(cornerRadius: CGFloat = 20, material: Material = .ultraThinMaterial) {
        self.cornerRadius = cornerRadius
        self.material = material
    }
    
    func body(content: Content) -> some View {
        content
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 20, material: Material = .ultraThinMaterial) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, material: material))
    }
}
