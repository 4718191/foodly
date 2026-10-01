import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Food.expiryDate) private var foods: [Food]
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory? = nil

    var filteredFoods: [Food] {
        var result = foods
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("카테고리", selection: $selectedCategory) {
                    Text("전체").tag(FoodCategory?.none)
                    ForEach(FoodCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(FoodCategory?.some(cat))
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if filteredFoods.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "등록된 음식이 없어요" : "검색 결과가 없어요",
                        systemImage: searchText.isEmpty ? "refrigerator" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "오른쪽 위 + 버튼을 눌러 음식을 추가해보세요" : "다른 검색어로 시도해보세요")
                    )
                } else {
                    List {
                        ForEach(filteredFoods) { food in
                            NavigationLink {
                                EditFoodView(food: food)
                            } label: {
                                HStack {
                                    if let imageData = food.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.gray.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                            .overlay(Image(systemName: "photo").foregroundStyle(.gray))
                                    }

                                    VStack(alignment: .leading) {
                                        Text(food.name)
                                            .font(.headline)
                                        Text("\(food.category.rawValue) · \(food.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline)
                                            .foregroundStyle(statusColor(for: food))
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteFood)
                    }
                }
            }
            .navigationTitle("유통기한 관리")
            .searchable(text: $searchText, prompt: "음식 이름 검색")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddFoodView()
            }
        }
    }
    
    func statusColor(for food: Food) -> Color {
        if food.daysRemaining < 0 {
            return .red
        } else if food.daysRemaining <= 3 {
            return .orange
        } else {
            return .green
        }
    }

    func deleteFood(at offsets: IndexSet) {
        for index in offsets {
            let food = filteredFoods[index]
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [food.id.uuidString])
            modelContext.delete(food)
        }
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Food.self, inMemory: true)
}
