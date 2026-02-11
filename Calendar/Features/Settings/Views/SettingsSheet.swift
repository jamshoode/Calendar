import SwiftUI

struct SettingsSheet: View {
  @Binding var isPresented: Bool
  @EnvironmentObject var appState: AppState
  @Environment(\.modelContext) private var modelContext
  #if DEBUG
    @EnvironmentObject var debugSettings: DebugSettings
  #endif

  // Holiday settings stored in shared UserDefaults
  @AppStorage(
    Constants.Holiday.apiKeyKey,
    store: UserDefaults(suiteName: Constants.Storage.appGroupIdentifier))
  private var holidayApiKey: String = ""

  @AppStorage(
    Constants.Holiday.countryCodeKey,
    store: UserDefaults(suiteName: Constants.Storage.appGroupIdentifier))
  private var holidayCountryCode: String = ""

  @AppStorage(
    Constants.Holiday.countryNameKey,
    store: UserDefaults(suiteName: Constants.Storage.appGroupIdentifier))
  private var holidayCountryName: String = ""

  @AppStorage(
    Constants.Holiday.languageNameKey,
    store: UserDefaults(suiteName: Constants.Storage.appGroupIdentifier))
  private var holidayLanguageName: String = ""

  @AppStorage(
    Constants.Weather.cityKey,
    store: UserDefaults(suiteName: Constants.Storage.appGroupIdentifier))
  private var weatherCity: String = ""

  @State private var isSyncing = false
  @State private var syncMessage: String?
  @State private var showCountryPicker = false

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

  private var lastSyncDateFormatted: String {
    let defaults = UserDefaults(suiteName: Constants.Storage.appGroupIdentifier)
    guard let date = defaults?.object(forKey: Constants.Holiday.lastSyncDateKey) as? Date else {
      return Localization.string(.holidayNever)
    }
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.locale = Localization.locale
    return formatter.string(from: date)
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          buildInfoSection
        }

        Section {
          holidaySection
        }

        #if DEBUG
          Section {
            debugSection
          }
        #endif
      }
      .navigationTitle(Localization.string(.settings))
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(Localization.string(.cancel)) {
            isPresented = false
          }
        }
      }
    }
    .sheet(isPresented: $showCountryPicker) {
      HolidayCountryPicker(
        apiKey: holidayApiKey,
        selectedCountryCode: $holidayCountryCode,
        selectedCountryName: $holidayCountryName,
        selectedLanguageName: $holidayLanguageName
      )
    }
  }

  // MARK: - Holiday Section

  private var holidaySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Localization.string(.holidays))
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.secondary)

      VStack(spacing: 0) {
        // API Key
        VStack(alignment: .leading, spacing: 6) {
          Text(Localization.string(.holidayApiKey))
            .font(.system(size: 14))
            .padding(.horizontal, 16)
            .padding(.top, 12)

          SecureField(Localization.string(.holidayApiKeyPlaceholder), text: $holidayApiKey)
            .font(.system(size: 14))
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }

        Divider().padding(.leading, 16)

        // Country
        Button(action: { showCountryPicker = true }) {
          HStack {
            Text(Localization.string(.holidayCountry))
              .font(.system(size: 14))
              .foregroundColor(.primary)
            Spacer()
            Text(
              holidayCountryName.isEmpty ? Localization.string(.holidayNone) : holidayCountryName
            )
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            Image(systemName: "chevron.right")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(.secondary)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Divider().padding(.leading, 16)

        // Language (read-only)
        SettingsRow(
          title: Localization.string(.holidayLanguage),
          value: holidayLanguageName.isEmpty ? "—" : holidayLanguageName
        )

        Divider().padding(.leading, 16)

        // Sync Now
        HStack {
          Button(action: syncHolidays) {
            HStack(spacing: 6) {
              if isSyncing {
                ProgressView()
                  .scaleEffect(0.8)
              }
              Text(
                isSyncing
                  ? Localization.string(.holidaySyncing) : Localization.string(.holidaySyncNow)
              )
              .font(.system(size: 14, weight: .medium))
            }
          }
          .disabled(isSyncing || holidayApiKey.isEmpty || holidayCountryCode.isEmpty)
          .buttonStyle(.plain)
          .foregroundColor(
            (isSyncing || holidayApiKey.isEmpty || holidayCountryCode.isEmpty)
              ? .secondary : .accentColor
          )

          Spacer()

          if let syncMessage = syncMessage {
            Text(syncMessage)
              .font(.system(size: 12))
              .foregroundColor(
                syncMessage == Localization.string(.holidaySyncSuccess) ? .green : .red)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        Divider().padding(.leading, 16)

        // Last Sync
        SettingsRow(
          title: Localization.string(.holidayLastSync),
          value: lastSyncDateFormatted
        )
      }
      .background(Color.secondaryFill)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }


  private func syncHolidays() {
    isSyncing = true
    syncMessage = nil
    Task {
      do {
        try await HolidayService.shared.syncHolidays(context: modelContext)
        await MainActor.run {
          isSyncing = false
          syncMessage = Localization.string(.holidaySyncSuccess)
        }
      } catch {
        await MainActor.run {
          isSyncing = false
          syncMessage = error.localizedDescription
        }
      }
    }
  }

  // MARK: - Build Info

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
      .background(Color.secondaryFill)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  // MARK: - Debug

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
        .background(Color.secondaryFill)
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
