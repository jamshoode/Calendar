import SwiftUI

#if DEBUG
struct DebugView: View {
    @EnvironmentObject var debugSettings: DebugSettings
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Theme Override", selection: $debugSettings.themeOverride) {
                    ForEach(DebugSettings.ThemeOverride.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                
                Text("Changes apply immediately.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Visual Debugging")) {
                Toggle("Show Borders", isOn: $debugSettings.showBorders)
            }
            
            Section(header: Text("Environment")) {
                Toggle("Mock Dates", isOn: $debugSettings.mockDates)
                
                Button("Reset On Launch") {
                    // Logic to toggle or trigger reset
                }
                .disabled(true)
            }
            
            Section(header: Text("Build Info")) {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                LabeledContent("Mode", value: "DEBUG")
            }
        }
        .navigationTitle("Debug")
    }
}
#endif
