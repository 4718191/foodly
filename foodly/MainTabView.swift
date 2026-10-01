import SwiftUI
import UIKit

struct MainTabView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("목록", systemImage: "list.bullet")
                }
            
            ShoppingListView()
                .tabItem {
                    Label("장바구니", systemImage: "cart")
                }

            StatsView()
                .tabItem {
                    Label("통계", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
        }
        .onAppear {
            applyAppearance(appearanceMode)
        }
        .onChange(of: appearanceMode) { _, newValue in
            applyAppearance(newValue)
        }
    }

    func applyAppearance(_ mode: String) {
        let style: UIUserInterfaceStyle
        switch mode {
        case "light": style = .light
        case "dark": style = .dark
        default: style = .unspecified
        }

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .forEach { scene in
                scene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = style
                }
            }
    }
}
