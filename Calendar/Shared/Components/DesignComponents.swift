import Combine
import SwiftUI

struct MeshGradientView: View {
    var colors: [Color] = Color.atmosphereBlue
    
    var body: some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: Array(colors.prefix(9))
            )
            .ignoresSafeArea()
        } else {
            // Fallback for older versions
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                Circle()
                    .fill(colors[0].opacity(0.4))
                    .frame(width: 600, height: 600)
                    .blur(radius: 100)
                    .offset(x: -200, y: -200)
                
                Circle()
                    .fill(colors[1].opacity(0.3))
                    .frame(width: 500, height: 500)
                    .blur(radius: 80)
                    .offset(x: 200, y: 300)
                
                Circle()
                    .fill(colors[2].opacity(0.2))
                    .frame(width: 400, height: 400)
                    .blur(radius: 60)
                    .offset(x: 0, y: -300)
            }
            .ignoresSafeArea()
        }
    }
}

struct GlassHaloModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.haloHighlight,
                                Color.haloHighlight.opacity(0),
                                Color.haloShadow.opacity(0.1),
                                Color.haloHighlight.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func glassHalo(cornerRadius: CGFloat = Spacing.cardRadius) -> some View {
        modifier(GlassHaloModifier(cornerRadius: cornerRadius))
    }
}
