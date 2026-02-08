import SwiftUI

struct TimerControls: View {
    let isRunning: Bool
    let isPaused: Bool
    let onPlay: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            ControlButton(icon: "arrow.counterclockwise", action: onReset)
            
            if isRunning && !isPaused {
                ControlButton(icon: "pause.fill", size: 80, isPrimary: true, action: onPause)
            } else {
                ControlButton(icon: "play.fill", size: 80, isPrimary: true, action: onPlay)
            }
            
            ControlButton(icon: "stop.fill", action: onStop)
        }
    }
}

struct ControlButton: View {
    let icon: String
    var size: CGFloat = 60
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.35, weight: .semibold))
                .frame(width: size, height: size)
                .foregroundColor(isPrimary ? .white : .primary)
                .background(backgroundView)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .pressableScale()
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isPrimary {
            Color.accentColor
                .clipShape(Circle())
        } else {
            Circle()
                .fill(.thinMaterial)
        }
    }
}

struct PressableScale: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func pressableScale() -> some View {
        modifier(PressableScale())
    }
}
