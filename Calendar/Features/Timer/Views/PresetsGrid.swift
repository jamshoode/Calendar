import SwiftUI

struct PresetsGrid: View {
    let presets: [TimerPreset]
    let onSelect: (TimerPreset) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(presets.sorted(by: { $0.order < $1.order })) { preset in
                PresetButton(preset: preset) {
                    onSelect(preset)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct PresetButton: View {
    let preset: TimerPreset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text("\(Int(preset.duration / 60))")
                    .font(.system(size: 24, weight: .bold))
                Text(Localization.string(.minutesUnit))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .glassBackground(cornerRadius: 12)
        }
        .buttonStyle(.plain)
    }
}
