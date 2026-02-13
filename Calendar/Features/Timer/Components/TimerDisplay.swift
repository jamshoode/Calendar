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
    // Note: totalDuration should probably come from viewModel, but keeping logic consistent with existing
    let totalDuration: TimeInterval = 3600 
    return 1.0 - (remainingTime / totalDuration)
  }

  var body: some View {
    ZStack {
      // Glow background
      Circle()
        .fill(Color.accentColor.opacity(0.05))
        .blur(radius: 40)

      Circle()
        .stroke(Color.textTertiary.opacity(0.1), lineWidth: 12)

      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          LinearGradient(
            colors: [.accentColor.opacity(0.7), .accentColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          style: StrokeStyle(lineWidth: 12, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(.linear(duration: 0.1), value: progress)
        .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 0)

      VStack(spacing: 8) {
          Text(formattedTime)
            .font(.system(size: 64, weight: .black, design: .rounded))
            .foregroundColor(.textPrimary)
            .monospacedDigit()
          
          if isRunning {
              Text(isStopwatch ? "ELAPSED" : "REMAINING")
                  .font(.system(size: 10, weight: .black))
                  .tracking(2)
                  .foregroundColor(.textTertiary)
          }
      }
    }
    .frame(width: 280, height: 280)
    .accessibilityLabel(Localization.string(.timeRemaining(formattedTime)))
  }
}
