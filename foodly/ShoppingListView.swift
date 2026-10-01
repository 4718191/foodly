import SwiftUI
import SwiftData
import WidgetKit

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingItem.createdAt) private var items: [ShoppingItem]
    @State private var newItemName = ""
    @State private var showingTransferSheet = false
    @State private var addAsFood = true

    private var trimmedName: String {
        newItemName.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    TextField("사야 할 것 추가", text: $newItemName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit(addItem)
                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(trimmedName.isEmpty)
                }
                .padding()

                if items.isEmpty {
                    ContentUnavailableView(
                        "장바구니가 비어있어요",
                        systemImage: "cart",
                        description: Text("사야 할 것을 위에서 추가해보세요")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            Button {
                                item.isChecked.toggle()
                                try? modelContext.save()
                                WidgetCenter.shared.reloadTimelines(ofKind: "FoodlyWidget")
                                WidgetCenter.shared.reloadTimelines(ofKind: "ShoppingWidget")
                            } label: {
                                HStack {
                                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isChecked ? .green : .secondary)
                                    Text(item.name)
                                        .strikethrough(item.isChecked)
                                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                                    if !item.isFood {
                                        Spacer()
                                        Image(systemName: "cart.badge.minus")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading) {
                                Button {
                                    item.isFood.toggle()
                                    try? modelContext.save()
                                    WidgetCenter.shared.reloadTimelines(ofKind: "FoodlyWidget")
                                    WidgetCenter.shared.reloadTimelines(ofKind: "ShoppingWidget")
                                } label: {
                                    if item.isFood {
                                        Label("생활용품으로", systemImage: "cart")
                                    } else {
                                        Label("식품으로", systemImage: "refrigerator")
                                    }
                                }
                                .tint(.orange)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("장바구니")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingTransferSheet = true
                        } label: {
                            Label("냉장고로 옮기기", systemImage: "refrigerator")
                        }
                        .disabled(!items.contains(where: { $0.isChecked && $0.isFood }))

                        Button(role: .destructive, action: clearChecked) {
                            Label("체크한 항목 삭제", systemImage: "trash")
                        }
                        .disabled(!items.contains(where: { $0.isChecked }))
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingTransferSheet) {
                TransferToFridgeView(checkedItems: items.filter { $0.isChecked && $0.isFood })
            }
        }
    }

    func addItem() {
        guard !trimmedName.isEmpty else { return }
        modelContext.insert(ShoppingItem(name: trimmedName))
        try? modelContext.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "FoodlyWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "ShoppingWidget")
        newItemName = ""
    }

    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "FoodlyWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "ShoppingWidget")
    }

    func clearChecked() {
        for item in items where item.isChecked {
            modelContext.delete(item)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "FoodlyWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "ShoppingWidget")
    }
}
