import SwiftUI

struct PomodoroView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var workSessions: Int = 0
    @State private var isWorkSession: Bool = true
    
    private let workDuration: TimeInterval = 25 * 60
    private let shortBreakDuration: TimeInterval = 5 * 60
    private let longBreakDuration: TimeInterval = 15 * 60
    private let sessionsBeforeLongBreak: Int = 4
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text(sessionLabel)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text("Session \(workSessions + 1) of \(sessionsBeforeLongBreak)")
                    .font(.system(size: 16))
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
                    viewModel.stopTimer()
                    resetPomodoro()
                }
            )
            
            if !viewModel.isRunning && !viewModel.isPaused {
                GlassButton(title: "Start Focus Session", icon: "play.fill", isPrimary: true) {
                    startNextSession()
                }
                
                if workSessions > 0 {
                    GlassButton(title: "Skip Break", icon: "forward.fill") {
                        skipBreak()
                    }
                }
            }
        }
        .padding()
        .onAppear {
            if viewModel.remainingTime == 0 && !viewModel.isRunning && !viewModel.isPaused {
                resetPomodoro()
            }
        }
        .onChange(of: viewModel.remainingTime) { _, newValue in
            if newValue == 0 && viewModel.isRunning {
                handleSessionComplete()
            }
        }
    }
    
    private var sessionLabel: String {
        if isWorkSession {
            return "Focus Time"
        } else if workSessions % sessionsBeforeLongBreak == 0 && workSessions > 0 {
            return "Long Break"
        } else {
            return "Short Break"
        }
    }
    
    private var currentDuration: TimeInterval {
        if isWorkSession {
            return workDuration
        } else if workSessions % sessionsBeforeLongBreak == 0 && workSessions > 0 {
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
        
        if isWorkSession {
            workSessions += 1
        }
        
        isWorkSession.toggle()
        
        let duration = currentDuration
        viewModel.remainingTime = duration
        
        AudioService.shared.playTimerEndSound()
    }
    
    private func skipBreak() {
        isWorkSession = true
        viewModel.stopTimer()
        let duration = currentDuration
        viewModel.remainingTime = duration
        viewModel.startTimer(duration: duration)
    }
    
    private func resetPomodoro() {
        workSessions = 0
        isWorkSession = true
        viewModel.remainingTime = workDuration
    }
}
