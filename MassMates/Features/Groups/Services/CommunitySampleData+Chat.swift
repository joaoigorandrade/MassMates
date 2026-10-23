import Foundation

extension CommunitySampleData {
    static func initialPinnedNotice(for groupId: String) -> GroupPinnedNotice {
        switch groupId {
        case parishFraternity.id:
            return pinnedNoticeSaoJose(groupId: groupId)
        case youthChallenge.id:
            return pinnedNoticeSaoMiguel(groupId: groupId)
        case "frat-santa-teresinha":
            return pinnedNoticeSantaTeresinha(groupId: groupId)
        default:
            return defaultPinnedNotice(groupId: groupId)
        }
    }

    static func initialChatMessages(for groupId: String) -> [GroupChatMessage] {
        switch groupId {
        case parishFraternity.id:
            return saoJoseChatMessages(groupId: groupId)
        case youthChallenge.id:
            return saoMiguelChatMessages(groupId: groupId)
        default:
            return defaultPastoralChatMessages(groupId: groupId)
        }
    }

    private static func pinnedNoticeSaoJose(groupId: String) -> GroupPinnedNotice {
        GroupPinnedNotice(
            id: "\(groupId)-notice-1",
            groupId: groupId,
            leaderName: "Pe. Lucas Mendes",
            noticeText: "Irmãos da Fraternidade: Terço dos Homens neste sábado às 7h00, seguido da Santa Missa às 7h30. Confissões na capela a partir das 6h30. Flores do altar organizadas pela equipe de acolhida.",
            updatedAtLabel: "Atualizado hoje"
        )
    }

    private static func pinnedNoticeSaoMiguel(groupId: String) -> GroupPinnedNotice {
        GroupPinnedNotice(
            id: "\(groupId)-notice-1",
            groupId: groupId,
            leaderName: "Gabriel Prado",
            noticeText: "Vigília Jovem — Constância: mantenham a fidelidade nos turnos de oração mental e partilhem os frutos da Lectio Divina matinal. Unidos sob a guarda de São Miguel!",
            updatedAtLabel: "Atualizado ontem"
        )
    }

    private static func pinnedNoticeSantaTeresinha(groupId: String) -> GroupPinnedNotice {
        GroupPinnedNotice(
            id: "\(groupId)-notice-1",
            groupId: groupId,
            leaderName: "Dona Teresa",
            noticeText: "Pequena Via: lembremo-nos das palavras de Santa Teresinha: “A oração é um impulso do coração”. Sexta-feira às 15h, Terço da Misericórdia na capela.",
            updatedAtLabel: "Atualizado há 2 dias"
        )
    }

    private static func defaultPinnedNotice(groupId: String) -> GroupPinnedNotice {
        GroupPinnedNotice(
            id: "\(groupId)-notice-1",
            groupId: groupId,
            leaderName: "Pe. Lucas Mendes",
            noticeText: "Horários de Confissão na Matriz: terças e quintas das 16h às 18h30; sábados das 9h às 11h. Quinta-feira às 19h30: Adoração Comunitária com bênção do Santíssimo.",
            updatedAtLabel: "Atualizado nesta semana"
        )
    }

    private static func saoJoseChatMessages(groupId: String) -> [GroupChatMessage] {
        [
            chat("1", groupId: groupId, author: "Carlos Eduardo", initials: "CE", text: "Salve Maria, irmãos! Quem pode ajudar a organizar as flores para o altar de São José neste sábado?", time: "há 45 min"),
            chat("2", groupId: groupId, author: "Diácono Paulo", initials: "DP", text: "Paz e bem! A sacristia já separou os vasos brancos. A Santa Missa votiva terá início pontualmente às 7h30.", time: "há 32 min"),
            chat("3", groupId: groupId, author: "Mateus Almeida", initials: "MA", text: "Estarei na igreja às 6h45 com as flores e folhetos para acolher os homens no Santo Terço às 7h00.", time: "há 18 min"),
            chat("4", groupId: groupId, author: "Rodrigo Silveira", initials: "RS", text: "Excelente, Mateus! Eu levarei os livretos com as ladainhas de São José Operário para distribuirmos.", time: "há 10 min"),
            chat("5", groupId: groupId, author: "Você", initials: "VC", text: "Contem comigo, irmãos. Chegarei às 6h45 para ajudar na recepção e organizar os bancos da igreja.", time: "há 3 min", isCurrent: true)
        ]
    }

    private static func saoMiguelChatMessages(groupId: String) -> [GroupChatMessage] {
        [
            chat("1", groupId: groupId, author: "Gabriel Prado", initials: "GP", text: "“Revesti-vos da armadura de Deus para resistir às ciladas do inimigo.” (Ef 6,11). Vigilantes na fé, jovens!", time: "há 1 h"),
            chat("2", groupId: groupId, author: "Beatriz Lima", initials: "BL", text: "Despertando para o turno das 05h da manhã! Oferecendo este início de dia pelo discernimento vocacional de todos.", time: "há 42 min"),
            chat("3", groupId: groupId, author: "Lucas M.", initials: "LM", text: "Turno da vigília concluído diante do Sacrário. Uma hora de profundo silêncio e entrega aos pés de Jesus.", time: "há 25 min"),
            chat("4", groupId: groupId, author: "Mariana Silva", initials: "MS", text: "Lectio Divina de hoje em Mc 1,35: “De manhã bem cedo, Jesus levantou-se e foi para um lugar deserto orar.” Que luz!", time: "há 12 min"),
            chat("5", groupId: groupId, author: "Você", initials: "VC", text: "Amém! Testemunho edificante de todos. Iniciando meu momento de oração mental e Lectio agora.", time: "há 4 min", isCurrent: true)
        ]
    }

    private static func defaultPastoralChatMessages(groupId: String) -> [GroupChatMessage] {
        [
            chat("1", groupId: groupId, author: "Pe. Lucas Mendes", initials: "LM", text: "Caros paroquianos, hoje teremos atendimento de Confissões na Matriz das 16h às 18h30 antes da Santa Missa.", time: "há 2 h"),
            chat("2", groupId: groupId, author: "Dona Teresa", initials: "DT", text: "Que bênção, Padre Lucas! Estarei lá para me preparar para a comunhão no domingo.", time: "há 1 h"),
            chat("3", groupId: groupId, author: "Clara Ribeiro", initials: "CR", text: "Padre, haverá atendimento de confissão no sábado pela manhã para quem trabalha fora durante a semana?", time: "há 35 min"),
            chat("4", groupId: groupId, author: "Pe. Lucas Mendes", initials: "LM", text: "Sim, Clara! Sábado teremos confissões das 09h às 11h na Capela. Ninguém fique sem a reconciliação.", time: "há 15 min"),
            chat("5", groupId: groupId, author: "Você", initials: "VC", text: "Muito obrigado pelas orientações e dedicação, Padre. Todos estaremos em oração pelo seu ministério.", time: "há 5 min", isCurrent: true)
        ]
    }

    private static func chat(
        _ id: String,
        groupId: String,
        author: String,
        initials: String,
        text: String,
        time: String,
        isCurrent: Bool = false
    ) -> GroupChatMessage {
        GroupChatMessage(
            id: "\(groupId)-msg-\(id)",
            groupId: groupId,
            authorName: author,
            authorInitials: initials,
            messageText: text,
            relativeTimeLabel: time,
            isCurrentUser: isCurrent
        )
    }
}
