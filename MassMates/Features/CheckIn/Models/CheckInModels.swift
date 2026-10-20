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

    init(
        practice: SpiritualPractice = .rosary,
        fruitOfPrayer: String = "",
        photoCaption: String = "",
        confessorOrPenanceNotes: String = "",
        destinationMode: CheckInDestinationMode = .selectedGroups,
        selectedGroupIds: Set<String> = []
    ) {
        self.practice = practice
        self.fruitOfPrayer = fruitOfPrayer
        self.photoCaption = photoCaption
        self.confessorOrPenanceNotes = confessorOrPenanceNotes
        self.destinationMode = practice.isStrictlyPrivate ? .privateDiaryOnly : destinationMode
        self.selectedGroupIds = practice.isStrictlyPrivate ? [] : selectedGroupIds
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
