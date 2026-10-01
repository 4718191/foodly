import AppIntents
import SwiftData
import WidgetKit

struct ToggleShoppingItemIntent: AppIntent {
    static var title: LocalizedStringResource = "장바구니 항목 체크"

    @Parameter(title: "Item ID")
    var itemIDString: String

    init() {}

    init(itemIDString: String) {
        self.itemIDString = itemIDString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: itemIDString) else {
            return .result()
        }

        let appGroupID = "group.com.hanju.foodly"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return .result()
        }
        let storeURL = groupURL.appendingPathComponent("foodly.sqlite")

        let schema = Schema([Food.self, ShoppingItem.self])
        let config = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<ShoppingItem>()
        let items = try context.fetch(descriptor)
        if let item = items.first(where: { $0.id == uuid }) {
            item.isChecked.toggle()
            try context.save()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "FoodlyWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "ShoppingWidget")
        return .result()
    }
}
