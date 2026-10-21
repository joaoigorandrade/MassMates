import Foundation

enum LiturgicalPosture: String, Sendable, Equatable {
    case standing = "De pé"
    case seated = "Sentados"
    case kneeling = "De joelhos"

    var systemImage: String {
        switch self {
        case .standing: "figure.stand"
        case .seated: "chair.lounge"
        case .kneeling: "figure.mind.and.body"
        }
    }
}

enum HolyMassRiteSection: String, CaseIterable, Identifiable, Sendable, Equatable {
    case initialRites
    case liturgyOfTheWord
    case eucharisticLiturgy
    case communionAndFinalRites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .initialRites: "Ritos Iniciais"
        case .liturgyOfTheWord: "Liturgia da Palavra"
        case .eucharisticLiturgy: "Liturgia Eucarística"
        case .communionAndFinalRites: "Comunhão & Ritos Finais"
        }
    }

    var systemImage: String {
        switch self {
        case .initialRites: "building.columns"
        case .liturgyOfTheWord: "book.pages"
        case .eucharisticLiturgy: "cup.and.saucer.fill"
        case .communionAndFinalRites: "sun.max.fill"
        }
    }

    var defaultPosture: LiturgicalPosture {
        switch self {
        case .initialRites: .standing
        case .liturgyOfTheWord: .seated
        case .eucharisticLiturgy: .kneeling
        case .communionAndFinalRites: .standing
        }
    }
}

struct MassDialogueTurn: Identifiable, Sendable, Equatable {
    let id: String
    let speaker: String
    let text: String
    let isAssembly: Bool
    let isCompactRow: Bool
}

enum HolyMassRitesCatalog {
    static let initialGreetingTurns: [MassDialogueTurn] = [
        MassDialogueTurn(
            id: "greet-1",
            speaker: "Celebrante",
            text: "Em nome do Pai e do Filho e do Espírito Santo.",
            isAssembly: false,
            isCompactRow: false
        ),
        MassDialogueTurn(
            id: "greet-2",
            speaker: "Todos",
            text: "Amém.",
            isAssembly: true,
            isCompactRow: false
        ),
        MassDialogueTurn(
            id: "greet-3",
            speaker: "Celebrante",
            text: "A graça de nosso Senhor Jesus Cristo, o amor do Pai e a comunhão do Espírito Santo estejam convosco.",
            isAssembly: false,
            isCompactRow: false
        ),
        MassDialogueTurn(
            id: "greet-4",
            speaker: "Todos",
            text: "Bendito seja Deus que nos reuniu no amor de Cristo.",
            isAssembly: true,
            isCompactRow: false
        )
    ]

    static let kyrieTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "kyrie-1", speaker: "Celebrante:", text: "Senhor, tende piedade de nós.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "kyrie-2", speaker: "Todos:", text: "Senhor, tende piedade de nós.", isAssembly: true, isCompactRow: true),
        MassDialogueTurn(id: "kyrie-3", speaker: "Celebrante:", text: "Cristo, tende piedade de nós.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "kyrie-4", speaker: "Todos:", text: "Cristo, tende piedade de nós.", isAssembly: true, isCompactRow: true)
    ]

    static let gospelDialogueTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "gosp-1", speaker: "Diácono/Padre:", text: "O Senhor esteja convosco.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "gosp-2", speaker: "Todos:", text: "Ele está no meio de nós.", isAssembly: true, isCompactRow: true),
        MassDialogueTurn(id: "gosp-3", speaker: "Diácono/Padre:", text: "Proclamação do Evangelho segundo Marcos.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "gosp-4", speaker: "Todos:", text: "Glória a vós, Senhor.", isAssembly: true, isCompactRow: true)
    ]

    static let offertoryTurns: [MassDialogueTurn] = [
        MassDialogueTurn(
            id: "off-1",
            speaker: "Celebrante",
            text: "Orai, irmãos e irmãs, para que o meu e vosso sacrifício seja aceito por Deus Pai todo-poderoso.",
            isAssembly: false,
            isCompactRow: false
        ),
        MassDialogueTurn(
            id: "off-2",
            speaker: "Todos (De pé)",
            text: "Receba o Senhor por tuas mãos este sacrifício, para a glória do seu nome, para nosso bem e de toda a santa Igreja.",
            isAssembly: true,
            isCompactRow: false
        )
    ]

    static let agnusDeiLines: [(lead: String, response: String)] = [
        ("«Cordeiro de Deus, que tirais o pecado do mundo, ", "tende piedade de nós.»"),
        ("«Cordeiro de Deus, que tirais o pecado do mundo, ", "tende piedade de nós.»"),
        ("«Cordeiro de Deus, que tirais o pecado do mundo, ", "dai-nos a paz.»")
    ]
}
