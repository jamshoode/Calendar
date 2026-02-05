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

  init(name: String, color: String = "blue", isPinned: Bool = false, sortOrder: Int = 0) {
    self.id = UUID()
    self.name = name
    self.color = color
    self.createdAt = Date()
    self.isPinned = isPinned
    self.sortOrder = sortOrder
    self.todos = []
  }
}
