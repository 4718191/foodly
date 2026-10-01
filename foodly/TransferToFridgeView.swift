import SwiftUI
import SwiftData

struct TransferDraft: Identifiable {
    let id = UUID()
    let shoppingItem: ShoppingItem
    var name: String
    var expiryDate: Date = Date()
    var category: FoodCategory = .fridge
}

struct TransferToFridgeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var drafts: [TransferDraft]

    init(checkedItems: [ShoppingItem]) {
        _drafts = State(initialValue: checkedItems.map {
            TransferDraft(shoppingItem: $0, name: $0.name)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                ForEach($drafts) { $draft in
                    Section(draft.name) {
                        DatePicker("유통기한", selection: $draft.expiryDate, displayedComponents: .date)
                        Picker("보관 방법", selection: $draft.category) {
                            ForEach(FoodCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                    }
                }
            }
            .navigationTitle("냉장고로 옮기기")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료", action: transferAll)
                }
            }
        }
    }

    func transferAll() {
        for draft in drafts {
            let newFood = Food(name: draft.name, expiryDate: draft.expiryDate, category: draft.category)
            modelContext.insert(newFood)
            modelContext.delete(draft.shoppingItem)
        }
        try? modelContext.save()
        dismiss()
    }
}
