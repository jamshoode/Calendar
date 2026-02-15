import SwiftUI

struct SplashView: View {
  @ObservedObject var manager: StartupManager

  var body: some View {
    ZStack {
      // Full-screen background to appear as a separate page
      VStack(spacing: 28) {
        Spacer()

        VStack(spacing: 12) {
          Image(systemName: "calendar")
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 72)
            .foregroundStyle(.white)

          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.2)
        }

        Text(
          manager.progressMessage.isEmpty
            ? Localization.string(.splashStarting) : manager.progressMessage
        )
        .foregroundColor(.white)
        .font(.title3)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)

        if manager.timedOut {
          Button(action: { manager.continueInBackground() }) {
            Text(Localization.string(.splashContinueInBackground))
              .bold()
              .foregroundColor(.white)
              .padding()
              .frame(maxWidth: 280)
              .background(Color.black.opacity(0.25))
              .cornerRadius(12)
          }
          .accessibilityIdentifier("ContinueBackgroundButton")
        }

        Text(Localization.string(.splashPreGenerating))
          .foregroundColor(.white.opacity(0.9))
          .font(.caption)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 24)

        Spacer()
      }
      .padding(.vertical, 60)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("StartupSplashView")
    }
    .background(.black)
    .zIndex(9999)
  }
}
