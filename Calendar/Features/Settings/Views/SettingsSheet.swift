import SwiftUI

struct SettingsSheet: View {
  @Binding var isPresented: Bool
  #if DEBUG
    @EnvironmentObject var debugSettings: DebugSettings
  #endif

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }

  private var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
  }

  private var buildMode: String {
    #if DEBUG
      return "Debug"
    #else
      return "Release"
    #endif
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(Localization.string(.settings))
          .font(.system(size: 20, weight: .bold))

        Spacer()

        Button(action: {
          withAnimation(.easeInOut(duration: 0.25)) {
            isPresented = false
          }
        }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 24))
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 16)

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          buildInfoSection

          #if DEBUG
            debugSection
          #endif
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
      }
    }
  }

  private var buildInfoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Localization.string(.appInfo))
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.secondary)

      VStack(spacing: 0) {
        SettingsRow(title: Localization.string(.version), value: appVersion)
        Divider().padding(.leading, 16)
        SettingsRow(title: Localization.string(.build), value: buildNumber)
        Divider().padding(.leading, 16)
        SettingsRow(title: Localization.string(.mode), value: buildMode)
      }
      .background(Color.primary.opacity(0.05))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  #if DEBUG
    private var debugSection: some View {
      VStack(alignment: .leading, spacing: 12) {
        Text(Localization.string(.debugSettings))
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.secondary)

        VStack(spacing: 0) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Theme Override")
              .font(.system(size: 14))
              .padding(.horizontal, 16)
              .padding(.top, 12)

            Picker("", selection: $debugSettings.themeOverride) {
              ForEach(DebugSettings.ThemeOverride.allCases) { theme in
                Text(theme.rawValue).tag(theme)
              }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
          }

          Divider().padding(.leading, 16)

          Toggle(isOn: $debugSettings.showBorders) {
            Text("Show Borders")
              .font(.system(size: 14))
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)

          Divider().padding(.leading, 16)

          Toggle(isOn: $debugSettings.mockDates) {
            Text("Mock Dates")
              .font(.system(size: 14))
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
  #endif
}

struct SettingsRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack {
      Text(title)
        .font(.system(size: 14))
      Spacer()
      Text(value)
        .font(.system(size: 14))
        .foregroundColor(.secondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }
}
