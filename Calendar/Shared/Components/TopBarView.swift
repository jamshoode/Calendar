import SwiftUI

struct TopBarView: View {
  let title: String
  let onMenuTap: () -> Void

  var body: some View {
    HStack {
      Text(title)
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(.primary)

      Spacer()

      Button(action: onMenuTap) {
        Image(systemName: "line.3.horizontal")
          .font(.system(size: 20, weight: .medium))
          .foregroundColor(.primary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .frame(height: 56)
    .background(.ultraThinMaterial)
  }
}
