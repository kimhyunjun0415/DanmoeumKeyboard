import SwiftUI
@main
struct DanmoeumApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                KeyboardSettingsView()
                    .navigationTitle("단모음")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Image(systemName: "keyboard").foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }
}
