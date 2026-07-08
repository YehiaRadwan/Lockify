import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: LockifyStore

    var body: some View {
        List {
            if store.history.isEmpty {
                Text("No sessions yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.history) { session in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Unlocked \(session.unlockedMinutes) min")
                            .font(.headline)

                        Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(session.proofSummary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("History")
    }
}
