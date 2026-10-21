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

    static let commandmentGroups: [CommandmentExamGroup] = [
        CommandmentExamGroup(
            id: "cmd-1-2",
            title: "1º e 2º Mandamentos",
            badge: "Amor a Deus & Santo Nome",
            summary: "Amar a Deus sobre todas as coisas e não tomar Seu Santo Nome em vão.",
            category: .commandments,
            items: [
                CommandmentExamItem(id: "cmd-1a", question: "Negligenciei a oração pessoal ou rezei com pressa e indiferença?", sinNote: "Falta deliberada à oração diária e momentos de oração por negligência", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-1b", question: "Coloquei comodismo, trabalho ou aprovação dos outros acima da fé?", sinNote: "Colocar conforto material ou trabalho acima da vontade de Deus", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-2a", question: "Pronunciei o Nome Santo de Deus sem respeito, com ira ou leviandade?", sinNote: "Uso leviano do Santo Nome de Deus ou blasfêmias em momentos de irritação", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "cmd-3",
            title: "3º Mandamento",
            badge: "Domingo & Festas",
            summary: "Guardar os domingos e dias Santos de guarda com amor e descanso.",
            category: .commandments,
            items: [
                CommandmentExamItem(id: "cmd-3a", question: "Faltei à Santa Missa no domingo ou dia santo por culpa própria?", sinNote: "Falta à Santa Missa Dominical por preguiça ou comodismo", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-3b", question: "Deixei de santificar o Domingo com descanso, família e obras de caridade?", sinNote: "Trabalho servil excessivo aos domingos sem caridade ou necessidade", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "cmd-4-5",
            title: "4º e 5º Mandamentos",
            badge: "Família & Respeito à Vida",
            summary: "Honrar pai e mãe; não matar (inclui ódios, calúnias e escândalos).",
            category: .duties,
            items: [
                CommandmentExamItem(id: "cmd-4a", question: "Fui impaciente, ríspido ou ingrato com meus pais, cônjuge ou filhos?", sinNote: "Impaciência e respostas ríspidas em conversa familiar (3x)", isInitiallyChecked: true),
                CommandmentExamItem(id: "cmd-5a", question: "Alimentei ressentimento, recusa em perdoar ou desejei mal ao próximo?", sinNote: "Alimentar rancor, desejo de vingança ou ódio contra alguém", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "cmd-6-9",
            title: "6º e 9º Mandamentos",
            badge: "Pureza & Castidade",
            summary: "Guardar a castidade no corpo, nos olhares e nos pensamentos.",
            category: .capital,
            items: [
                CommandmentExamItem(id: "cmd-6a", question: "Fui vigilante nos olhos, telas e entretenimento, rejeitando a impureza?", sinNote: "Olhares impuros em telas e redes sociais consentidos sem vigilância", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-9a", question: "Consenti voluntariamente em pensamentos ou desejos contrários à pureza?", sinNote: "Consentimento deliberado em pensamentos impuros", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "cmd-7-8-10",
            title: "7º, 8º e 10º Mandamentos",
            badge: "Justiça, Verdade & Retidão",
            summary: "Não furtar, não levantar falso testemunho, não cobiçar os bens alheios.",
            category: .duties,
            items: [
                CommandmentExamItem(id: "cmd-7a", question: "Fui rigorosamente honesto nas horas de trabalho, acordos e bens alheios?", sinNote: "Pequenas mentiras ou desvios de tempo no cumprimento do trabalho", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-8a", question: "Falei mal de terceiros (maledicência) ou espalhei juízos precipitados?", sinNote: "Omissão em prestar ajuda fraterna a colega em necessidade", isInitiallyChecked: true)
            ]
        )
    ]

    static let initialNotes: [ConfessionPrivateNote] = [
        ConfessionPrivateNote(id: "note-1", text: "Impaciência e respostas ríspidas em conversa familiar (3x)", linkedExamItemID: "cmd-4a"),
        ConfessionPrivateNote(id: "note-2", text: "Distração deliberada e negligência na oração matutina", linkedExamItemID: nil),
        ConfessionPrivateNote(id: "note-3", text: "Omissão em prestar ajuda fraterna a colega em necessidade", linkedExamItemID: "cmd-8a")
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
