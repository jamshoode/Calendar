import SwiftUI

struct FloatingErrorView: View {
  @State private var message: String? = nil

  var body: some View {
    Group {
      if let msg = message {
        VStack {
          HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.white)
            Text(msg)
              .foregroundColor(.white)
              .font(.subheadline)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
            Spacer()
            Button(action: { message = nil }) {
              Image(systemName: "xmark")
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 14)
          .background(Color.red)
          .cornerRadius(12)
          .shadow(radius: 8)
          .padding(.horizontal, 12)
          Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: msg)
        .onTapGesture { message = nil }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .appErrorOccurred)) { note in
      if let msg = note.userInfo?["message"] as? String {
        withAnimation { message = msg }
        Task { @MainActor in
          try? await Task.sleep(nanoseconds: 4_000_000_000)
          withAnimation { message = nil }
        }
      }
    }
  }
}
