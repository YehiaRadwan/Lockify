import SwiftUI

@main
struct LockifyApp: App {
    @StateObject private var store = LockifyStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
