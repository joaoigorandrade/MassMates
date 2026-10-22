import Foundation

enum CheckInDestinationMode: String, CaseIterable, Identifiable, Sendable, Equatable, Codable {
    case selectedGroups
    case privateDiaryOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selectedGroups: "Compartilhar com Grupos"
        case .privateDiaryOnly: "Apenas no Meu Diário Privado"
        }
    }

    var systemImage: String {
        switch self {
        case .selectedGroups: "person.3"
        case .privateDiaryOnly: "lock.shield"
        }
    }
}

struct PrivateDiaryCheckInEntry: Identifiable, Sendable, Equatable, Hashable, Codable {
    let id: String
    let practice: SpiritualPractice
    let reflectionOrNotes: String?
    let confessorOrPenanceNotes: String?
    let createdAt: Date
}

struct CheckInSubmissionDraft: Sendable, Equatable {
    var practice: SpiritualPractice
    var fruitOfPrayer: String
    var photoCaption: String
    var confessorOrPenanceNotes: String
    var destinationMode: CheckInDestinationMode
    var selectedGroupIds: Set<String>
    var photoData: Data?

    init(
        practice: SpiritualPractice = .rosary,
        fruitOfPrayer: String = "",
        photoCaption: String = "",
        confessorOrPenanceNotes: String = "",
        destinationMode: CheckInDestinationMode = .selectedGroups,
        selectedGroupIds: Set<String> = [],
        photoData: Data? = nil
    ) {
        self.practice = practice
        self.fruitOfPrayer = fruitOfPrayer
        self.photoCaption = photoCaption
        self.confessorOrPenanceNotes = confessorOrPenanceNotes
        self.destinationMode = practice.isStrictlyPrivate ? .privateDiaryOnly : destinationMode
        self.selectedGroupIds = practice.isStrictlyPrivate ? [] : selectedGroupIds
        self.photoData = photoData
    }
}

struct CheckInSubmissionResult: Sendable, Equatable {
    let practice: SpiritualPractice
    let sharedGroupIds: [String]
    let savedToPrivateDiary: Bool
    let celebrationMessage: String
    let shouldShowPostCheckInSponsoredCard: Bool
}

enum CheckInValidationError: Error, Sendable, Equatable {
    case noGroupSelected
    case writtenFruitRequired(groupName: String)
    case photoWitnessRequired(groupName: String)

    var userMessage: String {
        switch self {
        case .noGroupSelected:
            "Selecione ao menos um grupo ou escolha “Apenas no Meu Diário Privado”."
        case .writtenFruitRequired(let groupName):
            "O grupo “\(groupName)” pede uma breve reflexão no Fruto da Oração."
        case .photoWitnessRequired(let groupName):
            "O grupo “\(groupName)” pede uma legenda de partilha fotográfica."
        }
    }
}

enum DiaryCategoryFilter: String, CaseIterable, Identifiable, Sendable, Equatable {
    case all = "Todos"
    case rosary = "Terço"
    case mass = "Missa"
    case gospel = "Evangelho"
    case mentalPrayer = "Oração Mental"
    case examen = "Exame"
    case confession = "Confissão"

    var id: String { rawValue }

    var practice: SpiritualPractice? {
        switch self {
        case .all: nil
        case .rosary: .rosary
        case .mass: .holyMass
        case .gospel: .dailyGospel
        case .mentalPrayer: .mentalPrayer
        case .examen: .confession
        case .confession: .confession
        }
    }
}

extension SpiritualPractice {
    var checkInChipTitle: String {
        switch self {
        case .rosary: "Terço"
        case .holyMass: "Missa"
        case .dailyGospel: "Evangelho"
        case .adoration: "Adoração"
        case .mentalPrayer: "Oração Mental"
        case .spiritualReading: "Leitura"
        case .fasting: "Jejum"
        case .confession: "Confissão"
        }
    }

    var checkInIconName: String {
        switch self {
        case .rosary: "circle.inset.filled"
        case .holyMass: "church"
        case .dailyGospel: "book.closed"
        case .adoration: "sparkles"
        case .mentalPrayer: "figure.mind.and.body"
        case .spiritualReading: "text.book.closed"
        case .fasting: "flame"
        case .confession: "lock"
        }
    }
}

