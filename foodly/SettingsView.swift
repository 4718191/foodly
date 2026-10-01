import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    var body: some View {
        NavigationStack {
            Form {
                Section("화면 모드") {
                    Picker("화면 모드", selection: $appearanceMode) {
                        Text("시스템 설정 따르기").tag("system")
                        Text("라이트 모드").tag("light")
                        Text("다크 모드").tag("dark")
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("설정")
        }
    }
}
