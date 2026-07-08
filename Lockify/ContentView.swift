import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: LockifyStore

    var body: some View {
        NavigationStack {
            Group {
                if let session = store.activeSession {
                    UnlockSessionView(session: session)
                } else {
                    LockedHomeView()
                }
            }
            .navigationTitle("Lockify")
            .toolbar {
                NavigationLink("History") {
                    HistoryView()
                }
            }
        }
    }
}
