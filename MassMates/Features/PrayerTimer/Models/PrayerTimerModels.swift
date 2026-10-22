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

    var pillLabel: String {
        switch self {
        case .mentalPrayer: "Silêncio"
        case .rosary: "Terço"
        }
    }

    var associatedPractice: SpiritualPractice {
        switch self {
        case .mentalPrayer: .mentalPrayer
        case .rosary: .rosary
        }
    }
}

enum AmbientSoundOption: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case monasteryChimes
    case gentleRain
    case pureSilence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monasteryChimes: "Carrilhões de Mosteiro"
        case .gentleRain: "Chuva Suave & Vento"
        case .pureSilence: "Silêncio Puro"
        }
    }

    var systemImage: String {
        switch self {
        case .monasteryChimes: "church.fill"
        case .gentleRain: "drop.fill"
        case .pureSilence: "speaker.slash.fill"
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
        case .joyful: "Segunda-feira & Sábado"
        case .luminous: "Quinta-feira"
        case .sorrowful: "Terça & Sexta-feira"
        case .glorious: "Quarta-feira & Domingo"
        }
    }

    var descriptionText: String {
        switch self {
        case .joyful: "Contemplando a Encarnação do Verbo e a infância oculta de Jesus."
        case .luminous: "Contemplando a vida pública de Cristo, Luz do mundo."
        case .sorrowful: "Contemplando a Paixão redentora e o amor até o fim na Cruz."
        case .glorious: "Contemplando a vitória de Cristo sobre a morte e a glória celeste."
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
    let scriptureReference: String

    var id: Int { number }

    init(
        number: Int,
        title: String,
        fruitOfMystery: String,
        meditation: String,
        scriptureReference: String = "Marcos 16, 6"
    ) {
        self.number = number
        self.title = title
        self.fruitOfMystery = fruitOfMystery
        self.meditation = meditation
        self.scriptureReference = scriptureReference
    }
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
