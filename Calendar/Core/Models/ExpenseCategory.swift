import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
  case groceries
  case housing
  case transportation
  case subscriptions
  case healthcare
  case debt
  case entertainment
  case dining
  case shopping
  case other

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .groceries: return Localization.string(.expenseGroceries)
    case .housing: return Localization.string(.expenseHousing)
    case .transportation: return Localization.string(.expenseTransportation)
    case .subscriptions: return Localization.string(.expenseSubscriptions)
    case .healthcare: return Localization.string(.expenseHealthcare)
    case .debt: return Localization.string(.expenseDebt)
    case .entertainment: return Localization.string(.expenseEntertainment)
    case .dining: return Localization.string(.expenseDining)
    case .shopping: return Localization.string(.expenseShopping)
    case .other: return Localization.string(.expenseOther)
    }
  }

  var icon: String {
    switch self {
    case .groceries: return "cart.fill"
    case .housing: return "house.fill"
    case .transportation: return "car.fill"
    case .subscriptions: return "arrow.triangle.2.circlepath"
    case .healthcare: return "heart.fill"
    case .debt: return "creditcard.fill"
    case .entertainment: return "film.fill"
    case .dining: return "fork.knife"
    case .shopping: return "bag.fill"
    case .other: return "ellipsis.circle.fill"
    }
  }

  var color: Color {
    switch self {
    case .groceries: return .expenseGroceries
    case .housing: return .expenseHousing
    case .transportation: return .expenseTransport
    case .subscriptions: return .expenseSubscriptions
    case .healthcare: return .expenseHealthcare
    case .debt: return .expenseDebt
    case .entertainment: return .expenseEntertainment
    case .dining: return .expenseDining
    case .shopping: return .expenseShopping
    case .other: return .expenseOther
    }
  }
}
