import SwiftUI

struct CountdownView: View {
  @ObservedObject var viewModel: TimerViewModel
  let presets: [TimerPreset]

  var body: some View {
    VStack(spacing: 32) {
      TimerDisplay(
        remainingTime: viewModel.remainingTime, isRunning: viewModel.isRunning,
        isStopwatch: viewModel.isStopwatch)

      TimerControls(
        isRunning: viewModel.isRunning,
        isPaused: viewModel.isPaused,
        onPlay: {
          if viewModel.isPaused {
            viewModel.resumeTimer()
          } else if viewModel.remainingTime > 0 && !viewModel.isRunning {
            viewModel.startTimer(duration: viewModel.remainingTime)
          } else if let preset = viewModel.selectedPreset {
            viewModel.startTimer(duration: preset.duration)
          } else {
            viewModel.startStopwatch()
          }
        },
        onPause: {
          viewModel.pauseTimer()
        },
        onReset: {
          if viewModel.isStopwatch {
            viewModel.stopTimer()
          } else {
            viewModel.resetTimer()
          }
        },
        onStop: {
          viewModel.stopTimer()
          viewModel.selectedPreset = nil
        }
      )

      if !viewModel.isRunning && !viewModel.isPaused && !presets.isEmpty {
        PresetsGrid(presets: presets) { preset in
          viewModel.stopTimer()
          viewModel.selectedPreset = preset
          viewModel.startTimer(duration: preset.duration)
        }
      }

      Spacer()
    }
    .padding()
  }
}
