import SwiftUI

struct FloatingTabBar: View {
  @Binding var selectedTab: AppState.Tab?

  var body: some View {
    HStack(spacing: 0) {
      ForEach(AppState.Tab.allCases) { tab in
        let isSelected = selectedTab == tab
        Button {
          selectedTab = tab
        } label: {
          ZStack {
            // Indicator dot - positioned relative to icon
            Circle()
              .fill(Color.accentColor)
              .frame(width: 4, height: 4)
              .offset(y: 16)
              .opacity(isSelected ? 1 : 0)

            // Icon
            Image(systemName: tabIcon(for: tab))
              .font(.system(size: 20, weight: isSelected ? .bold : .medium))
              .foregroundColor(isSelected ? .accentColor : .textSecondary)
              .offset(y: isSelected ? -3 : 0)
              .scaleEffect(isSelected ? 1.05 : 1.0)
          }
          .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.1, dampingFraction: 0.9), value: isSelected)
      }
    }
    .padding(.horizontal, 8)
    .background(.ultraThinMaterial.opacity(0.8))
    .clipShape(Capsule())
    .glassHalo(cornerRadius: 100)
    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    .padding(.horizontal, 20)
    .padding(.bottom, 20)
  }

  private func tabIcon(for tab: AppState.Tab) -> String {
    switch tab {
    case .calendar: return "calendar"
    case .tasks: return "checklist"
    case .expenses: return "dollarsign.circle"
    case .clock: return "clock"
    case .weather: return "cloud.sun"
    }
  }
}
