import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var foods: [Food]

    var categoryCounts: [(category: FoodCategory, count: Int)] {
        FoodCategory.allCases.map { cat in
            (cat, foods.filter { $0.category == cat }.count)
        }
    }

    var statusCounts: [(status: String, count: Int, color: Color)] {
        let expired = foods.filter { $0.daysRemaining < 0 }.count
        let soon = foods.filter { $0.daysRemaining >= 0 && $0.daysRemaining <= 3 }.count
        let fresh = foods.filter { $0.daysRemaining > 3 }.count
        return [
            ("지남", expired, .red),
            ("임박", soon, .orange),
            ("여유", fresh, .green)
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                Section("전체 현황") {
                    HStack {
                        Text("총 보관 중인 음식")
                        Spacer()
                        Text("\(foods.count)개")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("유통기한 상태") {
                    Chart(statusCounts, id: \.status) { item in
                        BarMark(
                            x: .value("상태", item.status),
                            y: .value("개수", item.count)
                        )
                        .foregroundStyle(item.color)
                    }
                    .frame(height: 200)
                }

                Section("카테고리별 개수") {
                    Chart(categoryCounts, id: \.category) { item in
                        BarMark(
                            x: .value("카테고리", item.category.rawValue),
                            y: .value("개수", item.count)
                        )
                    }
                    .frame(height: 200)
                }
            }
            .navigationTitle("통계")
        }
    }
}
