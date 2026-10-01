import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

enum ShoppingFilter: String, AppEnum {
    case all
    case food
    case household

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "보여줄 항목"

    static var caseDisplayRepresentations: [ShoppingFilter: DisplayRepresentation] = [
        .all: "전체",
        .food: "식품",
        .household: "생활용품"
    ]
}

struct ShoppingWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "장바구니 위젯 설정"
    static var description = IntentDescription("보여줄 항목을 선택하세요")

    @Parameter(title: "보여줄 항목", default: .all)
    var filter: ShoppingFilter
}

struct ShoppingWidgetEntry: TimelineEntry {
    let date: Date
    let items: [ShoppingEntryItem]
}

struct ShoppingProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ShoppingWidgetEntry {
        ShoppingWidgetEntry(date: Date(), items: [])
    }

    func snapshot(for configuration: ShoppingWidgetConfigurationIntent, in context: Context) async -> ShoppingWidgetEntry {
        loadEntry(filter: configuration.filter)
    }

    func timeline(for configuration: ShoppingWidgetConfigurationIntent, in context: Context) async -> Timeline<ShoppingWidgetEntry> {
        let entry = loadEntry(filter: configuration.filter)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    func loadEntry(filter: ShoppingFilter) -> ShoppingWidgetEntry {
        let appGroupID = "group.com.hanju.foodly"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return ShoppingWidgetEntry(date: Date(), items: [])
        }
        let storeURL = groupURL.appendingPathComponent("foodly.sqlite")

        do {
            let schema = Schema([Food.self, ShoppingItem.self])
            let config = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            let descriptor = FetchDescriptor<ShoppingItem>(sortBy: [SortDescriptor(\.createdAt)])
            let allItems = try context.fetch(descriptor)
            let unchecked = allItems.filter { !$0.isChecked }

            let filtered: [ShoppingItem]
            switch filter {
            case .all: filtered = unchecked
            case .food: filtered = unchecked.filter { $0.isFood }
            case .household: filtered = unchecked.filter { !$0.isFood }
            }

            return ShoppingWidgetEntry(
                date: Date(),
                items: filtered.prefix(8).map { ShoppingEntryItem(id: $0.id, name: $0.name) }
            )
        } catch {
            return ShoppingWidgetEntry(date: Date(), items: [])
        }
    }
}

struct ShoppingWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: ShoppingWidgetEntry

    var body: some View {
        if entry.items.isEmpty {
            emptyView
        } else {
            switch family {
            case .systemMedium:
                mediumFilledView
            default:
                smallFilledView
            }
        }
    }

    var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "cart")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("장바구니가 비었어요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // 작은 위젯: 왼쪽 위 제목, 오른쪽 위 총 개수, 아래로 최대 3개
    var smallFilledView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("장바구니")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                CountBadge(count: entry.items.count)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.items.prefix(3)) { item in
                    itemRow(item)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    var mediumFilledView: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.items.count)")
                    .font(.system(size: 34, weight: .bold))
                Text("장바구니")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(width: 70, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.items.prefix(4)) { item in
                    itemRow(item)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    func itemRow(_ item: ShoppingEntryItem) -> some View {
        Button(intent: ToggleShoppingItemIntent(itemIDString: item.id.uuidString)) {
            HStack(spacing: 8) {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(minWidth: 20, minHeight: 20)
            .background(Circle().fill(.orange))
    }
}

struct ShoppingWidget: Widget {
    let kind: String = "ShoppingWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ShoppingWidgetConfigurationIntent.self, provider: ShoppingProvider()) { entry in
            ShoppingWidgetEntryView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("장바구니")
        .description("사야 할 것을 보여주고 바로 체크할 수 있어요")
        .contentMarginsDisabled()
    }
}
