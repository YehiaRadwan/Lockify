import SwiftUI

struct UnlockSessionView: View {
    @EnvironmentObject private var store: LockifyStore
    let session: UnlockSession

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)

            Text("Unlocked")
                .font(.title2.weight(.semibold))

            Text(timeString(from: store.remainingSeconds))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text("Unlock granted for \(session.unlockedMinutes) minutes")
                .foregroundStyle(.secondary)

            Text(session.proofSummary)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Lock Now") {
                store.forceLockNow()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onReceive(timer) { _ in
            store.tick()
        }
    }

    private func timeString(from seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
