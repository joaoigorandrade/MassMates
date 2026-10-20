import Foundation

enum PrayerTimerMode: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case mentalPrayer
    case rosary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mentalPrayer: "Oração Mental"
        case .rosary: "Santo Terço"
        }
    }

    var associatedPractice: SpiritualPractice {
        switch self {
        case .mentalPrayer: .mentalPrayer
        case .rosary: .rosary
        }
    }
}

enum RosaryMysterySet: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case joyful
    case luminous
    case sorrowful
    case glorious

    var id: String { rawValue }

    var title: String {
        switch self {
        case .joyful: "Mistérios Gozosos"
        case .luminous: "Mistérios Luminosos"
        case .sorrowful: "Mistérios Dolorosos"
        case .glorious: "Mistérios Gloriosos"
        }
    }

    var daysLabel: String {
        switch self {
        case .joyful: "Segundas-feiras e Sábados"
        case .luminous: "Quintas-feiras"
        case .sorrowful: "Terças e Sextas-feiras"
        case .glorious: "Quartas-feiras e Domingos"
        }
    }

    static func forDate(_ date: Date, calendar: Calendar = .current) -> RosaryMysterySet {
        let weekday = calendar.component(.weekday, from: date)
        return switch weekday {
        case 2, 7: .joyful
        case 5: .luminous
        case 3, 6: .sorrowful
        default: .glorious
        }
    }
}

struct RosaryDecade: Identifiable, Sendable, Equatable, Hashable, Codable {
    let number: Int
    let title: String
    let fruitOfMystery: String
    let meditation: String

    var id: Int { number }
}

enum BeadHapticEvent: Sendable, Equatable {
    case none
    case ourFather
    case hailMary(Int)
    case decadeCompleted(Int)
    case rosaryCompleted
}

struct LockScreenPrayerState: Sendable, Equatable {
    let isActive: Bool
    let modeTitle: String
    let targetEndDate: Date?
    let remainingSeconds: Int
}

@MainActor
protocol PrayerLockScreenSynchronizing {
    var latestState: LockScreenPrayerState { get }
    func updateLockScreen(_ state: LockScreenPrayerState)
}

@MainActor
final class DefaultPrayerLockScreenSynchronizer: PrayerLockScreenSynchronizing {
    // MARK: - Dependencies & State
    private(set) var latestState = LockScreenPrayerState(
        isActive: false,
        modeTitle: PrayerTimerMode.mentalPrayer.title,
        targetEndDate: nil,
        remainingSeconds: 0
    )

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    func updateLockScreen(_ state: LockScreenPrayerState) {
        latestState = state
    }
}
