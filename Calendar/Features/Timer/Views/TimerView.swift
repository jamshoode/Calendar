import SwiftData
import SwiftUI

struct TimerView: View {
  @StateObject private var countdownViewModel = TimerViewModel(id: "countdown")
  @Query private var presets: [TimerPreset]
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    VStack(spacing: 6) {
      CountdownView(viewModel: countdownViewModel, presets: presets)
        .transition(.opacity)
    }
    .padding(.top, 8)
    .onAppear {
      if presets.isEmpty {
        for preset in TimerPreset.defaultPresets {
          modelContext.insert(preset)
        }
      }
    }
  }
}
