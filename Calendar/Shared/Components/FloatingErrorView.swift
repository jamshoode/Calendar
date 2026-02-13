import SwiftUI

struct FloatingErrorView: View {
  @State private var message: String? = nil

  var body: some View {
    Group {
      if let msg = message {
        VStack {
          HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: "exclamationmark.triangle.fill")
                  .font(.system(size: 14, weight: .bold))
                  .foregroundColor(.white)
            }
            
            Text(msg)
              .foregroundColor(.white)
              .font(.system(size: 14, weight: .bold))
              .lineLimit(2)
              .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: { message = nil }) {
              Image(systemName: "xmark")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 14, weight: .black))
            }
            .buttonStyle(.plain)
          }
          .padding(.vertical, 12)
          .padding(.horizontal, 16)
          .background(
              ZStack {
                  Color.red.opacity(0.8)
                  Color.black.opacity(0.2)
              }
          )
          .clipShape(RoundedRectangle(cornerRadius: 18))
          .glassHalo(cornerRadius: 18)
          .shadow(color: Color.red.opacity(0.4), radius: 15, x: 0, y: 8)
          .padding(.top, 12)
          .padding(.horizontal, 16)
          
          Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: msg)
        .onTapGesture { message = nil }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .appErrorOccurred)) { note in
      if let msg = note.userInfo?["message"] as? String {
        withAnimation { message = msg }
        Task { @MainActor in
          try? await Task.sleep(nanoseconds: 5_000_000_000)
          withAnimation { message = nil }
        }
      }
    }
  }
}
