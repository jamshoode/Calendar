Developer handoff.

Includes:
- tokens.json (source of truth).
- component specs in design/components.
- mock HTML for quick sanity checks.

SwiftUI example:
- Add colors to Assets.xcassets matching tokens.
- Use Color("primary") in code or create Color extension.

Example snippet:
extension Color {
  static let background = Color("background")
  static let primary = Color("primary")
}

Use dynamic type: Text(...).font(.system(size: Tokens.typography.scale.body))
