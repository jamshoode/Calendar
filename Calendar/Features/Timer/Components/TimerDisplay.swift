import SwiftUI

struct TimerDisplay: View {
    let remainingTime: TimeInterval
    let isRunning: Bool
    var isStopwatch: Bool = false
    
    private var formattedTime: String {
        Formatters.formatTimerDuration(remainingTime)
    }
    
    private var progress: Double {
        if isStopwatch {
            return 1.0
        }
        let totalDuration: TimeInterval = 3600
        return 1.0 - (remainingTime / totalDuration)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.border, lineWidth: 8)
            
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
                .accessibilityLabel(Localization.string(.timeRemaining(formattedTime)))
        }
        .frame(width: 280, height: 280)
    }
}
