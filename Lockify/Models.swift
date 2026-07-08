import Foundation

enum ProofType: String, Codable, CaseIterable, Identifiable {
    case text
    case photo
    case document

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "Text Proof"
        case .photo: return "Photo Upload"
        case .document: return "Document Upload"
        }
    }
}

struct ProofSubmission: Codable {
    let type: ProofType
    let details: String
    let estimatedWorkMinutes: Int
    let submittedAt: Date
}

struct UnlockSession: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    let endsAt: Date
    let unlockedMinutes: Int
    let proofSummary: String

    var isActive: Bool { Date() < endsAt }
}
