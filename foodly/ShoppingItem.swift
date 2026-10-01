import Foundation
import SwiftData

@Model
class ShoppingItem {
    var id: UUID = UUID()
    var name: String
    var isChecked: Bool
    var createdAt: Date
    var isFood: Bool

    init(name: String, isChecked: Bool = false, createdAt: Date = Date(), isFood: Bool = true) {
        self.name = name
        self.isChecked = isChecked
        self.createdAt = createdAt
        self.isFood = isFood
    }
}
