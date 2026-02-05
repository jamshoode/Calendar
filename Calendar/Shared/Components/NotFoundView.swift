import SwiftUI

struct NotFoundView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text(Localization.string(.pageNotFound))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(Localization.string(.selectTabPrompt))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .glassEffect()
        .padding()
    }
}

#Preview {
    NotFoundView()
        .background(Color.gray.opacity(0.1))
}
