import Foundation

final class LockifyStore: ObservableObject {
    @Published private(set) var activeSession: UnlockSession?
    @Published private(set) var history: [UnlockSession] = []

    private let defaults: UserDefaults
    private let historyKey = "lockify.unlock.history"
    private let activeSessionKey = "lockify.active.session"
    private let lastResetDayKey = "lockify.last.reset.day"
    private let screenTimeController: ScreenTimeControlling

    init(
        defaults: UserDefaults = .standard,
        screenTimeController: ScreenTimeControlling = ScreenTimeControllerFactory.makeController()
    ) {
        self.defaults = defaults
        self.screenTimeController = screenTimeController

        loadState()
        performDailyResetIfNeeded()
        refreshActiveSessionState()
    }

    var isLocked: Bool {
        activeSession == nil
    }

    var remainingSeconds: Int {
        guard let activeSession else { return 0 }
        return max(Int(activeSession.endsAt.timeIntervalSinceNow), 0)
    }

    func submitProof(type: ProofType, details: String, estimatedWorkMinutes: Int) {
        performDailyResetIfNeeded()

        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedEstimate = max(1, estimatedWorkMinutes)
        let minutes = calculateUnlockMinutes(fromEstimatedWorkMinutes: sanitizedEstimate)

        let session = UnlockSession(
            id: UUID(),
            startedAt: Date(),
            endsAt: Date().addingTimeInterval(TimeInterval(minutes * 60)),
            unlockedMinutes: minutes,
            proofSummary: "\(type.title): \(trimmed.isEmpty ? "No details" : trimmed)"
        )

        activeSession = session
        history.insert(session, at: 0)
        saveState()

        screenTimeController.beginUnlockSession(until: session.endsAt)
    }

    func tick() {
        performDailyResetIfNeeded()
        refreshActiveSessionState()
    }

    func forceLockNow() {
        activeSession = nil
        saveState()
        screenTimeController.endUnlockSession()
    }

    func calculateUnlockMinutes(fromEstimatedWorkMinutes estimate: Int) -> Int {
        let baseGrant = Int(Double(estimate) * 0.75)
        return min(max(baseGrant, 5), 120)
    }

    private func refreshActiveSessionState() {
        guard let activeSession else { return }

        if Date() >= activeSession.endsAt {
            self.activeSession = nil
            saveState()
            screenTimeController.endUnlockSession()
        }
    }

    private func performDailyResetIfNeeded() {
        let calendar = Calendar.current
        let now = Date()

        if let lastReset = defaults.object(forKey: lastResetDayKey) as? Date,
           calendar.isDate(lastReset, inSameDayAs: now) {
            return
        }

        defaults.set(now, forKey: lastResetDayKey)
        if activeSession != nil {
            activeSession = nil
            screenTimeController.endUnlockSession()
        }
        saveState()
    }

    private func loadState() {
        let decoder = JSONDecoder()

        if let historyData = defaults.data(forKey: historyKey),
           let decoded = try? decoder.decode([UnlockSession].self, from: historyData) {
            history = decoded
        }

        if let sessionData = defaults.data(forKey: activeSessionKey),
           let decoded = try? decoder.decode(UnlockSession.self, from: sessionData) {
            activeSession = decoded
        }
    }

    private func saveState() {
        let encoder = JSONEncoder()

        defaults.set(try? encoder.encode(history), forKey: historyKey)
        defaults.set(try? encoder.encode(activeSession), forKey: activeSessionKey)
    }
}
