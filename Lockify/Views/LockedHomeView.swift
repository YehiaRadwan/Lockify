import SwiftUI

struct LockedHomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(.red)

            Text("Locked for Focus")
                .font(.title2.weight(.semibold))

            Text("Submit proof of work to unlock for a limited time.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            NavigationLink {
                ProofSubmissionView()
            } label: {
                Text("Submit Proof of Work")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
