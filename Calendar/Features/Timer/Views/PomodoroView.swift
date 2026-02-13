import SwiftUI

struct PomodoroView: View {
  @ObservedObject var viewModel: TimerViewModel

  private let workDuration: TimeInterval = 25 * 60
  private let shortBreakDuration: TimeInterval = 5 * 60
  private let longBreakDuration: TimeInterval = 15 * 60
  private let sessionsBeforeLongBreak: Int = 4

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        VStack(spacing: 6) {
          Text(sessionLabel)
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.secondary)

          Text(
            Localization.string(.pomodoroSession(viewModel.workSessions + 1, sessionsBeforeLongBreak))
          )
          .font(.system(size: 14))
          .foregroundColor(.secondary)
        }

        TimerDisplay(remainingTime: viewModel.remainingTime, isRunning: viewModel.isRunning)

        TimerControls(
          isRunning: viewModel.isRunning,
          isPaused: viewModel.isPaused,
          onPlay: {
            if viewModel.isPaused {
              viewModel.resumeTimer()
            } else if viewModel.remainingTime > 0 && !viewModel.isRunning {
              viewModel.startTimer(duration: viewModel.remainingTime)
            } else {
              startNextSession()
            }
          },
          onPause: {
            viewModel.pauseTimer()
          },
          onReset: {
            resetPomodoro()
          },
          onStop: {
            stopPomodoro()
          }
        )

        if !viewModel.isRunning && !viewModel.isPaused {
          GlassButton(title: "Start Focus Session", icon: "play.fill", isPrimary: true) {
            startNextSession()
          }

          if viewModel.workSessions > 0 {
            GlassButton(title: "Skip Break", icon: "forward.fill") {
              skipBreak()
            }
          }
        }
      }
      .padding()
      .padding(.bottom, 100) // Space for floating tab bar
    }
    .scrollIndicators(.hidden)
    .onAppear {
      if viewModel.remainingTime == 0 && !viewModel.isRunning && !viewModel.isPaused {
        let duration = currentDuration
        viewModel.remainingTime = duration
      }
    }
    .onChange(of: viewModel.remainingTime) { _, newValue in
      if newValue == 0 && viewModel.isRunning {
        handleSessionComplete()
      }
    }
  }

  private var sessionLabel: String {
    if viewModel.isWorkSession {
      return "Focus Time"
    } else if viewModel.workSessions % sessionsBeforeLongBreak == 0 && viewModel.workSessions > 0 {
      return "Long Break"
    } else {
      return "Short Break"
    }
  }

  private var currentDuration: TimeInterval {
    if viewModel.isWorkSession {
      return workDuration
    } else if viewModel.workSessions % sessionsBeforeLongBreak == 0 && viewModel.workSessions > 0 {
      return longBreakDuration
    } else {
      return shortBreakDuration
    }
  }

  private func startNextSession() {
    let duration = currentDuration
    viewModel.startTimer(duration: duration)
  }

  private func handleSessionComplete() {
    viewModel.stopTimer()

    if viewModel.isWorkSession {
      viewModel.workSessions += 1
    }

    viewModel.isWorkSession.toggle()
    viewModel.updatePomodoroState(sessions: viewModel.workSessions, isWork: viewModel.isWorkSession)

    let duration = currentDuration
    viewModel.remainingTime = duration

    AudioService.shared.playTimerEndSound()
  }

  private func skipBreak() {
    viewModel.isWorkSession = true
    viewModel.stopTimer()
    viewModel.updatePomodoroState(sessions: viewModel.workSessions, isWork: true)

    let duration = currentDuration
    viewModel.remainingTime = duration
    viewModel.startTimer(duration: duration)
  }

  private func stopPomodoro() {
    viewModel.pauseTimer()
    viewModel.remainingTime = currentDuration
  }

  private func resetPomodoro() {
    viewModel.terminateSession(remaining: workDuration)
    viewModel.updatePomodoroState(sessions: 0, isWork: true)
  }
}
