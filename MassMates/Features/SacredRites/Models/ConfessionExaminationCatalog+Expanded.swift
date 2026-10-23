import Foundation

// MARK: - Expanded Examination of Conscience (Adult Life, Capital Sins & Duties of State)

extension ConfessionExaminationCatalog {
    static let adultCommandmentGroups: [CommandmentExamGroup] = [
        CommandmentExamGroup(
            id: "cmd-adult-1-3",
            title: "1º, 2º e 3º Mandamentos",
            badge: "Deus, Santo Nome & Domingo",
            summary: "Amar a Deus sobre todas as coisas, honrar Seu Nome e santificar o Dia do Senhor.",
            category: .commandments,
            items: [
                CommandmentExamItem(id: "cmd-1a", question: "Negligenciei a oração pessoal ou reduzi a fé a ritos superficiais sem entrega de coração?", sinNote: "Falta deliberada à oração pessoal e abandono da vida com Deus", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-1b", question: "Coloquei dinheiro, carreira, aprovação social ou superstições acima da vontade de Deus?", sinNote: "Idolatria do dinheiro, sucesso ou práticas supersticiosas", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-2a", question: "Pronunciei o Santo Nome de Deus com leviandade, em momentos de ira ou sem respeito?", sinNote: "Uso leviano ou desrespeitoso do Santo Nome de Deus", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-3a", question: "Faltei à Santa Missa dominical ou aos dias santos de guarda por preguiça ou comodismo?", sinNote: "Falta culposa à Santa Missa de preceito", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-3b", question: "Deixei de santificar o Domingo com descanso piedoso, vida familiar e obras de caridade?", sinNote: "Trabalho servil desnecessário e negligência na santificação do Domingo", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "cmd-adult-4-5",
            title: "4º e 5º Mandamentos",
            badge: "Família & Respeito à Vida",
            summary: "Honrar os pais, cuidar da família e respeitar a dignidade sagrada de cada vida.",
            category: .commandments,
            items: [
                CommandmentExamItem(id: "cmd-4a", question: "Fui impaciente, ingrato ou desatento com meus pais, cônjuge ou filhos?", sinNote: "Impaciência e rispidez no convívio familiar", isInitiallyChecked: true),
                CommandmentExamItem(id: "cmd-4b", question: "Deixei de dedicar tempo de qualidade ao lar ou falhei na educação espiritual dos dependentes?", sinNote: "Omissão na formação cristã e atenção aos familiares", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-5a", question: "Alimentei ressentimento, recusa em perdoar, ódio ou desejei vingança contra alguém?", sinNote: "Rancor persistente e recusa ao perdão sincero", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-5b", question: "Prejudiquei minha saúde com excessos ou coloquei a vida própria e alheia em risco?", sinNote: "Falta de temperança e dano deliberado à saúde ou segurança", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "cmd-adult-6-9",
            title: "6º e 9º Mandamentos",
            badge: "Castidade & Pureza de Coração",
            summary: "Viver a pureza nos olhares, telas, relacionamentos e pensamentos consentidos.",
            category: .commandments,
            items: [
                CommandmentExamItem(id: "cmd-6a", question: "Fui vigilante nos olhos e nas telas, rejeitando conteúdos sensuais, pornografia e curiosidade impura?", sinNote: "Falta de custódia dos olhos e entretenimento impuro em telas", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-6b", question: "Cometi atos impuros contra a castidade do próprio corpo ou no trato com os outros?", sinNote: "Pecado deliberado contra a santa castidade", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-9a", question: "Consenti deliberadamente em pensamentos lascivos ou desejos contrários à fidelidade?", sinNote: "Consentimento em pensamentos impuros e desejos desordenados", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "cmd-adult-7-8-10",
            title: "7º, 8º e 10º Mandamentos",
            badge: "Honestidade, Verdade & Desapego",
            summary: "Praticar rigorosa justiça no trabalho, verdade nas palavras e desprendimento dos bens.",
            category: .commandments,
            items: [
                CommandmentExamItem(id: "cmd-7a", question: "Fui rigorosamente justo nas horas de trabalho, tributos e respeito aos bens alheios e comuns?", sinNote: "Desonestidade profissional, retenção indevida ou fraude contratual", isInitiallyChecked: false),
                CommandmentExamItem(id: "cmd-8a", question: "Falei mal dos outros (maledicência), espalhei fofocas ou menti para tirar vantagens?", sinNote: "Maledicência, quebra de reputação alheia ou mentira deliberada", isInitiallyChecked: true),
                CommandmentExamItem(id: "cmd-10a", question: "Invejei o sucesso e posses alheias ou alimentei apego avarento sem generosidade aos pobres?", sinNote: "Cobiça material e recusa em socorrer irmãos necessitados", isInitiallyChecked: false)
            ]
        )
    ]

    static let capitalSinsGroups: [CommandmentExamGroup] = [
        CommandmentExamGroup(
            id: "cap-sins-spirit",
            title: "Pecados Capitais do Espírito",
            badge: "Soberba, Inveja & Ira",
            summary: "Examinar as raízes do orgulho, do ciúme amargo e das reações coléricas.",
            category: .capital,
            items: [
                CommandmentExamItem(id: "cap-pride", question: "Agi com soberba, desprezando a opinião alheia, recusando pedir perdão ou buscando vaidade?", sinNote: "Soberba, autossuficiência e dificuldade de reconhecer limites e culpas", isInitiallyChecked: false),
                CommandmentExamItem(id: "cap-envy", question: "Entristeci-me com a virtude, sucesso ou progresso do próximo, desejando secretamente sua queda?", sinNote: "Inveja perante o bem e prosperidade do próximo", isInitiallyChecked: false),
                CommandmentExamItem(id: "cap-wrath", question: "Cedi a explosões de ira, agressividade verbal no lar/trânsito ou amargura guardada?", sinNote: "Falta de mansidão, acessos de ira e palavras ásperas", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "cap-sins-flesh",
            title: "Pecados Capitais da Carne & Vontade",
            badge: "Avareza, Luxúria, Gula & Preguiça",
            summary: "Vigiar contra as concupiscências materiais, intemperança e apatia espiritual.",
            category: .capital,
            items: [
                CommandmentExamItem(id: "cap-greed", question: "Apeguei-me desordenadamente ao dinheiro, esquecendo o dízimo e a esmola aos necessitados?", sinNote: "Avareza e recusa de partilha generosa com a Igreja e os pobres", isInitiallyChecked: false),
                CommandmentExamItem(id: "cap-lust", question: "Tratei pessoas como objetos de prazer próprio ou cedi a impulsos egoístas na afetividade?", sinNote: "Luxúria e busca egoísta de gratificação sensual", isInitiallyChecked: false),
                CommandmentExamItem(id: "cap-gluttony", question: "Comi ou bebi sem sobriedade, buscando na comida compensação para ansiedades e vazio?", sinNote: "Gula e falta de mortificação cristã nos sentidos", isInitiallyChecked: false),
                CommandmentExamItem(id: "cap-sloth", question: "Cedi à preguiça espiritual (acídia), postergando oração diária, confissão e deveres cotidianos?", sinNote: "Tibieza na oração diária, acídia e procrastinação culposa", isInitiallyChecked: false)
            ]
        )
    ]

    static let dutiesOfStateGroups: [CommandmentExamGroup] = [
        CommandmentExamGroup(
            id: "duty-state-work",
            title: "Ética Profissional & Responsabilidade",
            badge: "Trabalho & Sociedade",
            summary: "Santificar as tarefas profissionais com pontualidade, competência e justiça.",
            category: .duties,
            items: [
                CommandmentExamItem(id: "duty-work-1", question: "Cumpri minhas horas e tarefas com perfeição e pontualidade, sem desperdiçar o tempo pago?", sinNote: "Negligência e lentidão proposital no cumprimento das horas de trabalho", isInitiallyChecked: false),
                CommandmentExamItem(id: "duty-work-2", question: "Tratei com respeito e justiça subordinados, clientes e fornecedores, sem arrogância?", sinNote: "Injustiça ou humilhação no relacionamento profissional", isInitiallyChecked: false),
                CommandmentExamItem(id: "duty-work-3", question: "Fui conivente com práticas corruptas, atalhos ilícitos ou omissão da verdade no ofício?", sinNote: "Cumplicidade com fraudes ou quebra de padrões éticos profissionais", isInitiallyChecked: false)
            ]
        ),
        CommandmentExamGroup(
            id: "duty-state-home",
            title: "Caridade Conjugal & Vigilância Interior",
            badge: "Matrimônio & Vida Pessoal",
            summary: "Viver o amor oblativo no casamento, paciência mútua e guarda do coração.",
            category: .duties,
            items: [
                CommandmentExamItem(id: "duty-home-1", question: "Demonstrei carinho sincero, diálogo e escuta atenta ao cônjuge, evitando a frieza cotidiana?", sinNote: "Frieza afetiva e descaso pelo diálogo e companheirismo no matrimônio", isInitiallyChecked: false),
                CommandmentExamItem(id: "duty-home-2", question: "Procurei reconciliar-me antes de terminar o dia quando ocorreram desentendimentos familiares?", sinNote: "Manter silêncios punitivos e mágoas no ambiente do lar", isInitiallyChecked: false),
                CommandmentExamItem(id: "duty-home-3", question: "Mantive prudência e lealdade cristã, evitando intimidades e conversas arriscadas fora do casamento?", sinNote: "Imprudência emocional e risco à fidelidade conjugal", isInitiallyChecked: false)
            ]
        )
    ]

    static var expandedGroups: [CommandmentExamGroup] {
        adultCommandmentGroups + capitalSinsGroups + dutiesOfStateGroups
    }
}
