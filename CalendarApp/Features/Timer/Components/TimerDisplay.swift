import SwiftUI

struct TimerDisplay: View {
    let remainingTime: TimeInterval
    let isRunning: Bool
    
    private var formattedTime: String {
        Formatters.formatTimerDuration(remainingTime)
    }
    
    private var progress: Double {
        let totalDuration: TimeInterval = 3600
        return 1.0 - (remainingTime / totalDuration)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor.gradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            Text(formattedTime)
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .scaleEffect(isRunning ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRunning)
        }
        .frame(width: 280, height: 280)
    }
}
