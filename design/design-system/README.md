Design tokens for Calendar redesign.
- Use tokens.json as source of truth.
- Colors: minimal palette (background, surface, primary, accent).
- Typography: SF Pro Text, respect dynamic type.
- Spacing: use spacing scale for consistent layout.
- Motion: use motion timings for microinteractions.

Export tokens to iOS:
- Create Color assets in xcassets or generate via SwiftGen.
- Provide Token.swift with constants or use SwiftUI Color init from asset catalog.
