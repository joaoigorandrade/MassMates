import Foundation

enum ConfessionExaminationCatalog {
    static let fiveSteps: [GoodConfessionStep] = [
        GoodConfessionStep(
            number: 1,
            title: "Exame de Consciência",
            description: "Recordar com calma e verdade os pecados cometidos por atos, palavras e omissões.",
            isCompleted: true
        ),
        GoodConfessionStep(
            number: 2,
            title: "Dor dos Pecados (Contrição)",
            description: "Pesar de coração por haver ofendido a Deus, Sumo Bem e Pai misericordioso.",
            isCompleted: false
        ),
        GoodConfessionStep(
            number: 3,
            title: "Firme Propósito de Emenda",
            description: "Vontade sincera e resoluta de não pecar mais e afastar as ocasiões de pecado.",
            isCompleted: false
        ),
        GoodConfessionStep(
            number: 4,
            title: "Confissão Integral ao Sacerdote",
            description: "Acusar com clareza, verdade e humildade todos os pecados graves conhecidos.",
            isCompleted: false
        ),
        GoodConfessionStep(
            number: 5,
            title: "Cumprimento da Penitência",
            description: "Realizar com oração e reparação as preces ou obras indicadas pelo confessor.",
            isCompleted: false
        )
    ]

    static var commandmentGroups: [CommandmentExamGroup] {
        expandedGroups
    }

    static let initialNotes: [ConfessionPrivateNote] = [
        ConfessionPrivateNote(id: "note-1", text: "Impaciência e rispidez no convívio familiar", linkedExamItemID: "cmd-4a"),
        ConfessionPrivateNote(id: "note-2", text: "Tibieza na oração diária, acídia e procrastinação culposa", linkedExamItemID: "cap-sloth"),
        ConfessionPrivateNote(id: "note-3", text: "Maledicência, quebra de reputação alheia ou mentira deliberada", linkedExamItemID: "cmd-8a")
    ]

    static let penitentRiteSteps: [PenitentRiteStep] = [
        PenitentRiteStep(
            id: "rite-1",
            title: "1. Ao Ajoelhar / Sentar",
            trailingNote: nil,
            leadText: "O sacerdote abençoa. Você diz:",
            quoteText: "\"Abençoai-me, Padre, porque pequei. A minha última confissão bem feita foi há 24 dias.\"",
            closingResponse: nil,
            isHighlighted: false
        ),
        PenitentRiteStep(
            id: "rite-2",
            title: "2. A Acusação dos Pecados",
            trailingNote: nil,
            leadText: "Leia ou mencione com sinceridade suas faltas preparadas na lista acima. Conclua com:",
            quoteText: "\"Destes pecados e de todos aqueles de que não me recordo, peço perdão a Deus e a vós, Padre, a absolvição e a penitência.\"",
            closingResponse: nil,
            isHighlighted: false
        ),
        PenitentRiteStep(
            id: "rite-3",
            title: "3. Ato de Contrição",
            trailingNote: "Rezar quando o Padre solicitar",
            leadText: nil,
            quoteText: "\"Meu Deus, eu me arrependo de todo o coração de Vos ter ofendido, porque sois tão bom e amável. Prometo firmemente, com a ajuda da Vossa graça, nunca mais Vos ofender e fugir das ocasiões de pecar. Meu Jesus, misericórdia!\"",
            closingResponse: nil,
            isHighlighted: true
        ),
        PenitentRiteStep(
            id: "rite-4",
            title: "4. A Absolvição Sacerdotal",
            trailingNote: nil,
            leadText: "O sacerdote estende as mãos e profere as palavras sagradas:",
            quoteText: "\"... E eu te absolvo dos teus pecados, em nome do Pai, e do Filho e do Espírito Santo.\"",
            closingResponse: "Você faz o sinal da cruz e responde: \"Amém.\"",
            isHighlighted: false
        )
    ]
}
