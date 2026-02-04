import SwiftUI

struct CountdownView: View {
    @ObservedObject var viewModel: TimerViewModel
    let presets: [TimerPreset]
    
    var body: some View {
        VStack(spacing: 32) {
            TimerDisplay(remainingTime: viewModel.remainingTime, isRunning: viewModel.isRunning)
            
            TimerControls(
                isRunning: viewModel.isRunning,
                isPaused: viewModel.isPaused,
                onPlay: {
                    if viewModel.isPaused {
                        viewModel.resumeTimer()
                    } else if viewModel.remainingTime > 0 && !viewModel.isRunning {
                        viewModel.startTimer(duration: viewModel.remainingTime)
                    }
                },
                onPause: {
                    viewModel.pauseTimer()
                },
                onReset: {
                    viewModel.stopTimer()
                    viewModel.resetTimer()
                }
            )
            
            if !viewModel.isRunning && !viewModel.isPaused {
                PresetsGrid(presets: presets) { preset in
                    viewModel.stopTimer()
                    viewModel.selectedPreset = preset
                    viewModel.startTimer(duration: preset.duration)
                }
            }
        }
        .padding()
    }
}
