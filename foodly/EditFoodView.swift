import SwiftUI
import SwiftData
import PhotosUI

struct EditFoodView: View {
    @Bindable var food: Food
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                TextField("음식 이름", text: $food.name)
                DatePicker("유통기한", selection: $food.expiryDate, displayedComponents: .date)
                Picker("보관 방법", selection: $food.category) {
                    ForEach(FoodCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }

                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let imageData = food.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                        } else {
                            Label("사진 추가", systemImage: "camera")
                        }
                    }
                }
            }
            .navigationTitle("항목 수정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        food.imageData = data
                    }
                }
            }
        }
    }
}
