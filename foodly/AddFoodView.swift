import SwiftUI
import SwiftData
import UserNotifications
import PhotosUI

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var expiryDate = Date()
    @State private var category: FoodCategory = .fridge
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingScanner = false
    @State private var isLookingUp = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("음식 이름", text: $name)
                Button {
                    showingScanner = true
                } label: {
                    Label("바코드로 스캔하기", systemImage: "barcode.viewfinder")
                }
                DatePicker("유통기한", selection: $expiryDate, displayedComponents: .date)
                Picker("보관 방법", selection: $category) {
                    ForEach(FoodCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }

                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let imageData, let uiImage = UIImage(data: imageData) {
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
            .navigationTitle("새 항목 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let newFood = Food(name: name, expiryDate: expiryDate, category: category, imageData: imageData)
                        modelContext.insert(newFood)
                        try? modelContext.save()
                        scheduleNotification(for: newFood)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { code in
                    lookupProduct(barcode: code)
                }
            }
            .alert("상품 정보를 찾을 수 없어요", isPresented: $showingNotFoundAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("바코드는 인식했지만 데이터베이스에 등록된 상품 정보가 없어요. 이름을 직접 입력해주세요.")
            }
        }
    }

    func scheduleNotification(for food: Food) {
        guard let notifyDate = Calendar.current.date(byAdding: .day, value: -1, to: food.expiryDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "유통기한 임박"
        content.body = "\(food.name)의 유통기한이 내일까지예요!"
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notifyDate)
        dateComponents.hour = 9

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: food.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    
    @State private var showingNotFoundAlert = false

    func lookupProduct(barcode: String) {
        isLookingUp = true
        let apiKey = "aeee33a3597647c7b12b"
        let urlString = "http://openapi.foodsafetykorea.go.kr/api/\(apiKey)/C005/json/1/5/BAR_CD=\(barcode)"

        guard let url = URL(string: urlString) else {
            isLookingUp = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { DispatchQueue.main.async { isLookingUp = false } }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let c005 = json["C005"] as? [String: Any],
                  let rows = c005["row"] as? [[String: Any]],
                  let firstRow = rows.first,
                  let productName = firstRow["PRDLST_NM"] as? String,
                  !productName.isEmpty else {
                DispatchQueue.main.async {
                    showingNotFoundAlert = true
                }
                return
            }

            DispatchQueue.main.async {
                name = productName
            }
        }.resume()
    }}
