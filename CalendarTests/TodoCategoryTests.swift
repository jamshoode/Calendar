import XCTest
import SwiftData
@testable import Calendar

final class TodoCategoryTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: TodoViewModel!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: TodoCategory.self, TodoItem.self, configurations: config)
        context = ModelContext(container)
        viewModel = TodoViewModel()
    }

    func testCategoryNestingDepth() throws {
        let root = TodoCategory(name: "Root")
        context.insert(root)
        
        let child = TodoCategory(name: "Child")
        context.insert(child)
        child.parent = root
        
        let grandchild = TodoCategory(name: "Grandchild")
        context.insert(grandchild)
        grandchild.parent = child
        
        XCTAssertEqual(root.depth, 0)
        XCTAssertEqual(child.depth, 1)
        XCTAssertEqual(grandchild.depth, 2)
        
        XCTAssertTrue(root.canAcceptChild())
        XCTAssertTrue(child.canAcceptChild())
        XCTAssertFalse(grandchild.canAcceptChild())
    }

    func testCircularNestingPrevention() throws {
        let cat1 = TodoCategory(name: "Cat 1")
        context.insert(cat1)
        
        let cat2 = TodoCategory(name: "Cat 2")
        context.insert(cat2)
        cat2.parent = cat1
        
        // Try to set cat1's parent to cat2 via viewModel
        viewModel.updateCategory(cat1, name: "Cat 1", color: "blue", parent: cat2, context: context)
        
        XCTAssertNil(cat1.parent, "Should prevent circular nesting")
    }
}
