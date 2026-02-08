import SwiftUI

// MARK: - Spacing Tokens
// Standardized spacing values referenced everywhere instead of hardcoded magic numbers

struct Spacing {
  static let xxxs: CGFloat = 2
  static let xxs: CGFloat = 4
  static let xs: CGFloat = 8
  static let sm: CGFloat = 12
  static let md: CGFloat = 16
  static let lg: CGFloat = 20
  static let xl: CGFloat = 24
  static let xxl: CGFloat = 32
  static let xxxl: CGFloat = 48

  /// Standard card padding
  static let cardPadding: CGFloat = 16
  /// Standard section spacing
  static let sectionSpacing: CGFloat = 20
  /// Standard corner radius for cards
  static let cardRadius: CGFloat = 16
  /// Small corner radius for inline elements
  static let smallRadius: CGFloat = 10
  /// Large corner radius for sheets/modals
  static let sheetRadius: CGFloat = 24
}
