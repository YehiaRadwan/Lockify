import SwiftUI

struct ProofSubmissionView: View {
    @EnvironmentObject private var store: LockifyStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ProofType = .text
    @State private var workEstimate = 30
    @State private var proofDetails = ""

    private var predictedMinutes: Int {
        store.calculateUnlockMinutes(fromEstimatedWorkMinutes: workEstimate)
    }

    var body: some View {
        Form {
            Section("Proof") {
                Picker("Type", selection: $selectedType) {
                    ForEach(ProofType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }

                TextEditor(text: $proofDetails)
                    .frame(minHeight: 120)

                Text("Placeholder input supports notes for text/photo/document proof in MVP.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Work estimate") {
                Stepper("Estimated work: \(workEstimate) min", value: $workEstimate, in: 1...240, step: 5)
                Text("Predicted unlock: \(predictedMinutes) min")
                    .font(.headline)
            }

            Section {
                Button("Grant Timed Unlock") {
                    store.submitProof(type: selectedType, details: proofDetails, estimatedWorkMinutes: workEstimate)
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Proof of Work")
    }
}
