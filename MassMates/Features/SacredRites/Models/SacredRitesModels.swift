import Foundation

// MARK: - Nightly Examen Models

struct IgnatianGratitudeChip: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let systemImage: String

    static let defaults: [IgnatianGratitudeChip] = [
        IgnatianGratitudeChip(id: "familia", title: "Família & Lar", systemImage: "house"),
        IgnatianGratitudeChip(id: "trabalho", title: "Trabalho fecundo", systemImage: "briefcase"),
        IgnatianGratitudeChip(id: "paciencia", title: "Paciência concedida", systemImage: "leaf"),
        IgnatianGratitudeChip(id: "luz", title: "Luz na oração matinal", systemImage: "sun.max")
    ]
}

enum ExamenPresenceEvaluation: String, CaseIterable, Identifiable, Sendable, Equatable {
    case bem = "Bem"
    case comLuta = "Com luta"
    case falhei = "Falhei"

    var id: String { rawValue }
    var title: String { rawValue }
}

enum LectioResolutionEvaluation: String, CaseIterable, Identifiable, Sendable, Equatable {
    case fidelidade
    case deslize
    case graca

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fidelidade: "Fidelidade vivida"
        case .deslize: "Deslize com recomeço"
        case .graca: "Necessidade de graça"
        }
    }

    var systemImage: String {
        switch self {
        case .fidelidade: "checkmark.circle.fill"
        case .deslize: "arrow.counterclockwise"
        case .graca: "heart.fill"
        }
    }
}

struct ConscienceAttentionPrompt: Identifiable, Sendable, Equatable {
    let id: String
    let text: String

    static let defaults: [ConscienceAttentionPrompt] = [
        ConscienceAttentionPrompt(
            id: "impaciencia",
            text: "Fui apressado ou impaciente no trato com os outros?"
        ),
        ConscienceAttentionPrompt(
            id: "omissao",
            text: "Deixei de fazer o bem por comodismo ou omissão?"
        ),
        ConscienceAttentionPrompt(
            id: "vaidade",
            text: "Alimentei pensamentos de vaidade ou autopiedade?"
        )
    ]
}

struct ExamenVirtueOption: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let subtitle: String

    static let defaults: [ExamenVirtueOption] = [
        ExamenVirtueOption(id: "paciencia", title: "Paciência", subtitle: "No trato fraterno"),
        ExamenVirtueOption(id: "vigilancia", title: "Vigilância", subtitle: "Na oração matinal"),
        ExamenVirtueOption(id: "generosidade", title: "Generosidade", subtitle: "Silenciosa e oculta"),
        ExamenVirtueOption(id: "confianca", title: "Confiança", subtitle: "Abandono filial")
    ]
}

// MARK: - Confession Preparation Models

enum ConfessionTab: String, CaseIterable, Identifiable, Sendable, Equatable {
    case commandments
    case contrition
    case rite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .commandments: "Mandamentos"
        case .contrition: "Ato de Contrição"
        case .rite: "Rito"
        }
    }
}

struct GoodConfessionStep: Identifiable, Sendable, Equatable {
    let number: Int
    let title: String
    let description: String
    let isCompleted: Bool

    var id: Int { number }
}

enum ConfessionExamCategory: String, CaseIterable, Identifiable, Sendable, Equatable {
    case commandments
    case duties
    case capital

    var id: String { rawValue }

    var title: String {
        switch self {
        case .commandments: "Dez Mandamentos"
        case .duties: "Deveres de Estado"
        case .capital: "Pecados Capitais & Omissões"
        }
    }
}

struct CommandmentExamItem: Identifiable, Sendable, Equatable {
    let id: String
    let question: String
    let sinNote: String
    let isInitiallyChecked: Bool
}

struct CommandmentExamGroup: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let badge: String
    let summary: String
    let category: ConfessionExamCategory
    let items: [CommandmentExamItem]
}

struct ConfessionPrivateNote: Identifiable, Sendable, Equatable {
    let id: String
    let text: String
    let linkedExamItemID: String?
}

struct PenitentRiteStep: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let trailingNote: String?
    let leadText: String?
    let quoteText: String
    let closingResponse: String?
    let isHighlighted: Bool
}
