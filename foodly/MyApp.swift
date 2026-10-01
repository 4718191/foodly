import SwiftUI
import SwiftData
import UserNotifications

@main
struct MyApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("알림 권한: \(granted)")
        }

        let schema = Schema([Food.self, ShoppingItem.self])
        let appGroupID = "group.com.hanju.foodly"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("App Group을 찾을 수 없습니다")
        }
        let storeURL = groupURL.appendingPathComponent("foodly.sqlite")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
