import SwiftUI

struct NotFoundView: View {
  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "questionmark.circle.fill")
        .font(.system(size: 80))
        .foregroundColor(Color.textTertiary)

      Text(Localization.string(.pageNotFound))
        .font(Typography.largeTitle)
        .foregroundColor(Color.textPrimary)

      Text(Localization.string(.selectTabPrompt))
        .font(Typography.body)
        .foregroundColor(Color.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(40)
    .cardStyle()
    .padding()
  }
}

#Preview {
  NotFoundView()
    .background(Color.backgroundPrimary)
}
