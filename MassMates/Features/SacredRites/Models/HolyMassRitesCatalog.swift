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
    let latinText: String?
    let isAssembly: Bool
    let isCompactRow: Bool

    init(
        id: String,
        speaker: String,
        text: String,
        latinText: String? = nil,
        isAssembly: Bool,
        isCompactRow: Bool = false
    ) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.latinText = latinText
        self.isAssembly = isAssembly
        self.isCompactRow = isCompactRow
    }
}

enum HolyMassRitesCatalog {
    static let initialGreetingTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "greet-1", speaker: "Celebrante", text: "Em nome do Pai e do Filho e do Espírito Santo.", latinText: "In nómine Patris et Fílii et Spíritus Sancti.", isAssembly: false),
        MassDialogueTurn(id: "greet-2", speaker: "Todos", text: "Amém.", latinText: "Amen.", isAssembly: true),
        MassDialogueTurn(id: "greet-3", speaker: "Celebrante", text: "O Senhor esteja convosco.", latinText: "Dóminus vobíscum.", isAssembly: false),
        MassDialogueTurn(id: "greet-4", speaker: "Todos", text: "Ele está no meio de nós.", latinText: "Et cum spíritu tuo.", isAssembly: true)
    ]

    static let kyrieTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "kyrie-1", speaker: "Celebrante:", text: "Senhor, tende piedade de nós.", latinText: "Kýrie, eléison.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "kyrie-2", speaker: "Todos:", text: "Senhor, tende piedade de nós.", latinText: "Kýrie, eléison.", isAssembly: true, isCompactRow: true),
        MassDialogueTurn(id: "kyrie-3", speaker: "Celebrante:", text: "Cristo, tende piedade de nós.", latinText: "Christe, eléison.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "kyrie-4", speaker: "Todos:", text: "Cristo, tende piedade de nós.", latinText: "Christe, eléison.", isAssembly: true, isCompactRow: true),
        MassDialogueTurn(id: "kyrie-5", speaker: "Celebrante:", text: "Senhor, tende piedade de nós.", latinText: "Kýrie, eléison.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "kyrie-6", speaker: "Todos:", text: "Senhor, tende piedade de nós.", latinText: "Kýrie, eléison.", isAssembly: true, isCompactRow: true)
    ]

    static let gospelDialogueTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "gosp-1", speaker: "Diácono/Padre:", text: "O Senhor esteja convosco.", latinText: "Dóminus vobíscum.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "gosp-2", speaker: "Todos:", text: "Ele está no meio de nós.", latinText: "Et cum spíritu tuo.", isAssembly: true, isCompactRow: true),
        MassDialogueTurn(id: "gosp-3", speaker: "Diácono/Padre:", text: "Proclamação do Evangelho segundo Marcos.", latinText: "Léctio Sancti Evangélii secúndum Marcum.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "gosp-4", speaker: "Todos:", text: "Glória a vós, Senhor.", latinText: "Glória tibi, Dómine.", isAssembly: true, isCompactRow: true)
    ]

    static let offertoryTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "off-1", speaker: "Celebrante", text: "Orai, irmãos e irmãs, para que o meu e vosso sacrifício seja aceito por Deus Pai todo-poderoso.", latinText: "Oráte, fratres: ut meum ac vestrum sacrifícium acceptábile fiat apud Deum Patrem omnipoténtem.", isAssembly: false),
        MassDialogueTurn(id: "off-2", speaker: "Todos (De pé)", text: "Receba o Senhor por tuas mãos este sacrifício, para a glória do seu nome, para nosso bem e de toda a santa Igreja.", latinText: "Suscípiat Dóminus sacrifícium de mánibus tuis ad laudem et glóriam nóminis sui...", isAssembly: true)
    ]

    static let prefaceDialogueTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "pref-1", speaker: "Celebrante:", text: "O Senhor esteja convosco.", latinText: "Dóminus vobíscum.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "pref-2", speaker: "Todos:", text: "Ele está no meio de nós.", latinText: "Et cum spíritu tuo.", isAssembly: true, isCompactRow: true),
        MassDialogueTurn(id: "pref-3", speaker: "Celebrante:", text: "Corações ao alto.", latinText: "Sursum corda.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "pref-4", speaker: "Todos:", text: "O nosso coração está em Deus.", latinText: "Habémus ad Dóminum.", isAssembly: true, isCompactRow: true),
        MassDialogueTurn(id: "pref-5", speaker: "Celebrante:", text: "Demos graças ao Senhor nosso Deus.", latinText: "Grátias agámus Dómino Deo nostro.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "pref-6", speaker: "Todos:", text: "É nosso dever e nossa salvação.", latinText: "Dignum et iustum est.", isAssembly: true, isCompactRow: true)
    ]

    static let mysteryOfFaithTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "mysterium-1", speaker: "Celebrante:", text: "Eis o mistério da fé!", latinText: "Mystérium fídei.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "mysterium-2", speaker: "Todos:", text: "Anunciamos, Senhor, a vossa morte e proclamamos a vossa ressurreição. Vinde, Senhor Jesus!", latinText: "Mortem tuam annuntiámus, Dómine, et tuam resurrectiónem confitémur, donec vénias.", isAssembly: true, isCompactRow: true)
    ]

    static let communionInvitationTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "comm-inv-1", speaker: "Celebrante:", text: "Eis o Cordeiro de Deus, que tira o pecado do mundo.", latinText: "Ecce Agnus Dei, ecce qui tollit peccáta mundi.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "comm-inv-2", speaker: "Todos:", text: "Senhor, eu não sou digno(a) de que entreis em minha morada, mas dizei uma palavra e serei salvo(a).", latinText: "Dómine, non sum dignus, ut intres sub tectum meum, sed tantum dic verbo et sanábitur ánima mea.", isAssembly: true, isCompactRow: true)
    ]

    static let dismissalTurns: [MassDialogueTurn] = [
        MassDialogueTurn(id: "dism-1", speaker: "Celebrante:", text: "O Senhor esteja convosco.", latinText: "Dóminus vobíscum.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "dism-2", speaker: "Todos:", text: "Ele está no meio de nós.", latinText: "Et cum spíritu tuo.", isAssembly: true, isCompactRow: true),
        MassDialogueTurn(id: "dism-3", speaker: "Celebrante:", text: "Ide em paz e o Senhor vos acompanhe.", latinText: "Ite, missa est.", isAssembly: false, isCompactRow: true),
        MassDialogueTurn(id: "dism-4", speaker: "Todos:", text: "Graças a Deus.", latinText: "Deo grátias.", isAssembly: true, isCompactRow: true)
    ]

    static let agnusDeiLines: [(lead: String, response: String)] = [
        ("«Cordeiro de Deus, que tirais o pecado do mundo, ", "tende piedade de nós.»"),
        ("«Cordeiro de Deus, que tirais o pecado do mundo, ", "tende piedade de nós.»"),
        ("«Cordeiro de Deus, que tirais o pecado do mundo, ", "dai-nos a paz.»")
    ]
}
