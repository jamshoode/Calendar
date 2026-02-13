import Foundation
import SwiftData

@Model
class TodoCategory {
  var id: UUID
  var name: String
  var color: String
  var createdAt: Date
  var isPinned: Bool
  var sortOrder: Int

  @Relationship(deleteRule: .cascade, inverse: \TodoItem.category)
  var todos: [TodoItem]?

  var parent: TodoCategory?

  @Relationship(deleteRule: .cascade, inverse: \TodoCategory.parent)
  var subcategories: [TodoCategory]?

  init(name: String, color: String = "blue", isPinned: Bool = false, sortOrder: Int = 0) {
    self.id = UUID()
    self.name = name
    self.color = color
    self.createdAt = Date()
    self.isPinned = isPinned
    self.sortOrder = sortOrder
    self.todos = []
    self.subcategories = []
  }

  var allSubcategories: [TodoCategory] {
    subcategories ?? []
  }

  var depth: Int {
    var currentDepth = 0
    var currentParent = parent
    while let p = currentParent {
      currentDepth += 1
      currentParent = p.parent
    }
    return currentDepth
  }

  func canAcceptChild() -> Bool {
    return depth < 2 // 0 = root, 1 = parent, 2 = child. Level 2 cannot have children as that would be Level 3 which is the limit.
  }
}
