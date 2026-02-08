import SwiftUI

struct TopBarView: View {
  let title: String
  let onMenuTap: () -> Void

  var body: some View {
    HStack {
      Text(title)
        .font(Typography.title)
        .foregroundColor(.textPrimary)

      Spacer()

      Button(action: onMenuTap) {
        Image(systemName: "gearshape")
          .font(.system(size: 20, weight: .medium))
          .foregroundColor(.textSecondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, Spacing.md)
    .frame(height: 56)
    .background(Color.backgroundPrimary)
  }
}
