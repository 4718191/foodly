import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct ShoppingEntryItem: Identifiable {
    let id: UUID
    let name: String
}

struct FoodEntry: TimelineEntry {
    let date: Date
    let urgentCount: Int
    let nextFoodName: String?
    let shoppingCount: Int
    let shoppingItems: [ShoppingEntryItem]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> FoodEntry {
        FoodEntry(date: Date(), urgentCount: 0, nextFoodName: nil, shoppingCount: 0, shoppingItems: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (FoodEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FoodEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func loadEntry() -> FoodEntry {
        let appGroupID = "group.com.hanju.foodly"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return FoodEntry(date: Date(), urgentCount: 0, nextFoodName: nil, shoppingCount: 0, shoppingItems: [])
        }
        let storeURL = groupURL.appendingPathComponent("foodly.sqlite")

        do {
            let schema = Schema([Food.self, ShoppingItem.self])
            let config = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            let foodDescriptor = FetchDescriptor<Food>(sortBy: [SortDescriptor(\.expiryDate)])
            let foods = try context.fetch(foodDescriptor)

            let urgent = foods.filter { food in
                let days = Calendar.current.dateComponents([.day], from: Date(), to: food.expiryDate).day ?? 0
                return days <= 3
            }

            let shoppingDescriptor = FetchDescriptor<ShoppingItem>(sortBy: [SortDescriptor(\.createdAt)])
            let shoppingItems = try context.fetch(shoppingDescriptor)
            let unchecked = shoppingItems.filter { !$0.isChecked }

            return FoodEntry(
                date: Date(),
                urgentCount: urgent.count,
                nextFoodName: foods.first?.name,
                shoppingCount: unchecked.count,
                shoppingItems: unchecked.prefix(4).map { ShoppingEntryItem(id: $0.id, name: $0.name) }
            )
        } catch {
            return FoodEntry(date: Date(), urgentCount: 0, nextFoodName: nil, shoppingCount: 0, shoppingItems: [])
        }
    }
}

struct FoodlyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "refrigerator.fill")
                    .foregroundStyle(.blue)
                Text("\(entry.urgentCount)")
                    .font(.title2)
                    .bold()
                Text("임박")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let name = entry.nextFoodName {
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack {
                Image(systemName: "cart.fill")
                    .foregroundStyle(.orange)
                Text("\(entry.shoppingCount)")
                    .font(.title2)
                    .bold()
                Text("살 것")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    var mediumView: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "refrigerator.fill")
                        .foregroundStyle(.blue)
                    Text("\(entry.urgentCount)개 임박")
                        .font(.headline)
                }
                if let name = entry.nextFoodName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("장바구니")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if entry.shoppingItems.isEmpty {
                    Text("살 것 없음")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.shoppingItems) { item in
                        Button(intent: ToggleShoppingItemIntent(itemIDString: item.id.uuidString)) {
                            HStack {
                                Image(systemName: "circle")
                                    .font(.caption)
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

struct FoodlyWidget: Widget {
    let kind: String = "FoodlyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FoodlyWidgetEntryView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("유통기한 관리")
        .description("임박한 음식과 장바구니를 보여줘요")
    }
}
