import Combine
import CoreGraphics
import Foundation

@MainActor
final class DesklyViewModel: ObservableObject {
    @Published var phases: [WorkPhase]
    @Published private(set) var currentIndex: Int
    @Published private(set) var remainingSeconds: TimeInterval
    @Published private(set) var isRunning: Bool
    @Published private(set) var isCompleted: Bool
    @Published private(set) var alarmActive = false
    @Published var soundEnabled: Bool {
        didSet {
            if !soundEnabled { stopAlarm() }
            save()
            rescheduleNotifications()
        }
    }
    @Published var draggedPhaseID: UUID?
    @Published var dropTargetID: UUID?

    private var deadline: Date?
    private var cancellables: Set<AnyCancellable> = []
    private let defaultsKey = "deskly.ios.state.v1"

    var currentPhase: WorkPhase? {
        phases.indices.contains(currentIndex) ? phases[currentIndex] : nil
    }

    var nextPhase: WorkPhase? {
        phases.indices.contains(currentIndex + 1) ? phases[currentIndex + 1] : nil
    }

    var progress: Double {
        guard let currentPhase else { return 0 }
        let total = Double(currentPhase.minutes * 60)
        return total > 0 ? min(1, max(0, 1 - remainingSeconds / total)) : 0
    }

    var formattedTime: String {
        let seconds = max(0, Int(ceil(remainingSeconds)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let state = try? JSONDecoder().decode(SavedState.self, from: data),
           !state.phases.isEmpty {
            phases = state.phases
            currentIndex = min(state.currentIndex, state.phases.count - 1)
            remainingSeconds = state.remainingSeconds
            isRunning = state.isRunning
            isCompleted = state.isCompleted
            soundEnabled = state.soundEnabled
            deadline = state.deadline
        } else {
            let plan = WorkPhase.standardPlan
            phases = plan
            currentIndex = 0
            remainingSeconds = Double(plan[0].minutes * 60)
            isRunning = false
            isCompleted = false
            soundEnabled = true
        }

        NotificationCenter.default.publisher(for: .desklyStopAlarm)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.stopAlarm() }
            .store(in: &cancellables)

        if isRunning { tick(at: Date(), playAlarm: false) }
    }

    func requestNotificationPermission() {
        Task { await NotificationService.shared.requestAuthorization() }
    }

    func toggleRunning() {
        stopAlarm()
        if isCompleted {
            resetDay()
            return
        }
        if isRunning {
            if let deadline { remainingSeconds = max(0, deadline.timeIntervalSinceNow) }
            self.deadline = nil
            isRunning = false
            NotificationService.shared.cancelPending()
        } else {
            deadline = Date().addingTimeInterval(max(1, remainingSeconds))
            isRunning = true
            rescheduleNotifications()
        }
        save()
    }

    func tick(at now: Date = Date(), playAlarm: Bool = true) {
        guard isRunning, var nextDeadline = deadline else { return }
        var changedPhase = false

        while now >= nextDeadline {
            if phases.indices.contains(currentIndex + 1) {
                currentIndex += 1
                changedPhase = true
                nextDeadline = nextDeadline.addingTimeInterval(Double(phases[currentIndex].minutes * 60))
            } else {
                remainingSeconds = 0
                deadline = nil
                isRunning = false
                isCompleted = true
                changedPhase = true
                NotificationService.shared.cancelPending()
                break
            }
        }

        if isRunning {
            deadline = nextDeadline
            remainingSeconds = max(0, nextDeadline.timeIntervalSince(now))
        }

        if changedPhase && playAlarm {
            alarmActive = true
            if soundEnabled { AlarmPlayer.shared.start() }
        }
        if changedPhase { save() }
    }

    func skip() {
        navigate(to: min(phases.count - 1, currentIndex + 1))
    }

    func previous() {
        navigate(to: max(0, currentIndex - 1))
    }

    private func navigate(to index: Int) {
        guard phases.indices.contains(index) else { return }
        stopAlarm()
        currentIndex = index
        isCompleted = false
        remainingSeconds = Double(phases[index].minutes * 60)
        deadline = isRunning ? Date().addingTimeInterval(remainingSeconds) : nil
        rescheduleNotifications()
        save()
    }

    func resetDay() {
        stopAlarm()
        currentIndex = 0
        isCompleted = false
        isRunning = false
        deadline = nil
        remainingSeconds = Double(phases.first?.minutes ?? 1) * 60
        NotificationService.shared.cancelPending()
        save()
    }

    func restoreStandardPlan() {
        stopAlarm()
        phases = WorkPhase.standardPlan
        currentIndex = 0
        remainingSeconds = Double(phases[0].minutes * 60)
        isRunning = false
        isCompleted = false
        deadline = nil
        NotificationService.shared.cancelPending()
        save()
    }

    func stopAlarm() {
        AlarmPlayer.shared.stop()
        alarmActive = false
        NotificationService.shared.clearDelivered()
    }

    func add(kind: PhaseKind) {
        let insertion = min(phases.count, currentIndex + 1)
        phases.insert(WorkPhase(kind: kind), at: insertion)
        planDidChange()
    }

    func update(_ phase: WorkPhase) {
        guard let index = phases.firstIndex(where: { $0.id == phase.id }) else { return }
        phases[index] = phase
        if index == currentIndex {
            remainingSeconds = min(remainingSeconds, Double(phase.minutes * 60))
            deadline = isRunning ? Date().addingTimeInterval(remainingSeconds) : nil
        }
        planDidChange()
    }

    func remove(_ phase: WorkPhase) {
        guard phases.count > 1, let index = phases.firstIndex(of: phase) else { return }
        phases.remove(at: index)
        if currentIndex >= phases.count { currentIndex = phases.count - 1 }
        if index < currentIndex { currentIndex -= 1 }
        remainingSeconds = min(remainingSeconds, Double(phases[currentIndex].minutes * 60))
        deadline = isRunning ? Date().addingTimeInterval(remainingSeconds) : nil
        planDidChange()
    }

    func beginDragging(_ phase: WorkPhase) {
        draggedPhaseID = phase.id
        dropTargetID = nil
    }

    func targetDrop(on phase: WorkPhase) {
        guard draggedPhaseID != phase.id else { return }
        dropTargetID = phase.id
    }

    func completeDrop(before target: WorkPhase) {
        defer { cancelDragging() }
        guard let draggedPhaseID,
              let sourceIndex = phases.firstIndex(where: { $0.id == draggedPhaseID }),
              let targetIndex = phases.firstIndex(of: target),
              sourceIndex != targetIndex else { return }
        let currentID = currentPhase?.id
        let item = phases.remove(at: sourceIndex)
        let adjustedTarget = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        phases.insert(item, at: adjustedTarget)
        if let currentID, let newCurrent = phases.firstIndex(where: { $0.id == currentID }) {
            currentIndex = newCurrent
        }
        planDidChange()
    }

    func cancelDragging() {
        draggedPhaseID = nil
        dropTargetID = nil
    }

    func cardWidth(for phase: WorkPhase) -> CGFloat {
        min(220, max(124, CGFloat(96 + phase.minutes)))
    }

    func sceneBecameActive() {
        tick(at: Date(), playAlarm: false)
    }

    func sceneMovedToBackground() {
        save()
        rescheduleNotifications()
    }

    private func planDidChange() {
        rescheduleNotifications()
        save()
    }

    private func rescheduleNotifications() {
        guard isRunning else {
            NotificationService.shared.cancelPending()
            return
        }
        let phases = phases
        let index = currentIndex
        let remaining = remainingSeconds
        let sound = soundEnabled
        Task {
            await NotificationService.shared.scheduleRemaining(
                phases: phases,
                currentIndex: index,
                remainingSeconds: remaining,
                soundEnabled: sound
            )
        }
    }

    private func save() {
        let state = SavedState(
            phases: phases,
            currentIndex: currentIndex,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            isCompleted: isCompleted,
            soundEnabled: soundEnabled,
            deadline: deadline
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}

private struct SavedState: Codable {
    var phases: [WorkPhase]
    var currentIndex: Int
    var remainingSeconds: TimeInterval
    var isRunning: Bool
    var isCompleted: Bool
    var soundEnabled: Bool
    var deadline: Date?
}
