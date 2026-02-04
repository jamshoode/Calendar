import SwiftUI

struct SwipeGestureModifier: ViewModifier {
    let onLeft: () -> Void
    let onRight: () -> Void
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height
                        
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            if horizontalAmount < -50 {
                                onLeft()
                            } else if horizontalAmount > 50 {
                                onRight()
                            }
                        }
                    }
            )
    }
}

extension View {
    func swipeGesture(onLeft: @escaping () -> Void, onRight: @escaping () -> Void) -> some View {
        modifier(SwipeGestureModifier(onLeft: onLeft, onRight: onRight))
    }
}
