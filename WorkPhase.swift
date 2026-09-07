import Foundation

enum PhaseKind: String, Codable, CaseIterable, Identifiable {
    case officeChair
    case standing
    case movement
    case exerciseBall
    case lunch
    case custom

    var id: String { rawValue }

    var defaultName: String {
        switch self {
        case .officeChair: "Sitzen · Bürostuhl"
        case .standing: "Stehen"
        case .movement: "Bewegung"
        case .exerciseBall: "Sitzen · Sitzball"
        case .lunch: "Mittagspause"
        case .custom: "Eigene Phase"
        }
    }

    var systemImage: String {
        switch self {
        case .officeChair: "chair.fill"
        case .standing: "figure.stand"
        case .movement: "figure.walk"
        case .exerciseBall: "circle.dotted"
        case .lunch: "fork.knife"
        case .custom: "sparkles"
        }
    }

    var defaultMinutes: Int {
        switch self {
        case .officeChair: 45
        case .standing: 30
        case .movement: 10
        case .exerciseBall: 15
        case .lunch: 30
        case .custom: 20
        }
    }
}

struct WorkPhase: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var minutes: Int
    var kind: PhaseKind

    init(name: String? = nil, minutes: Int? = nil, kind: PhaseKind) {
        self.name = name ?? kind.defaultName
        self.minutes = minutes ?? kind.defaultMinutes
        self.kind = kind
    }
}

extension WorkPhase {
    static var standardPlan: [WorkPhase] {
        [
            WorkPhase(minutes: 45, kind: .officeChair),
            WorkPhase(minutes: 30, kind: .standing),
            WorkPhase(minutes: 45, kind: .officeChair),
            WorkPhase(minutes: 15, kind: .exerciseBall),
            WorkPhase(minutes: 45, kind: .officeChair),
            WorkPhase(minutes: 30, kind: .standing),
            WorkPhase(minutes: 45, kind: .officeChair),
            WorkPhase(minutes: 15, kind: .exerciseBall),
            WorkPhase(name: "Pause · idealerweise etwas gehen", minutes: 30, kind: .lunch),
            WorkPhase(minutes: 30, kind: .standing),
            WorkPhase(minutes: 45, kind: .officeChair),
            WorkPhase(minutes: 15, kind: .exerciseBall),
            WorkPhase(minutes: 30, kind: .standing),
            WorkPhase(minutes: 45, kind: .officeChair),
            WorkPhase(minutes: 15, kind: .exerciseBall),
            WorkPhase(minutes: 30, kind: .standing)
        ]
    }
}
