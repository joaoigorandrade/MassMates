import Foundation

enum SpiritualDiarySampleData: Sendable {
    static func realisticSeedEntries() -> [PrivateDiaryCheckInEntry] {
        confessionEntries()
            + lectioDivinaEntries()
            + mentalPrayerEntries()
            + liturgicalDevotionEntries()
    }

    private static func anchorDate(daysAgo: Double, hour: Double = 8) -> Date {
        let daySeconds: Double = 86_400
        let daysSinceEpoch = (Date().timeIntervalSince1970 / daySeconds).rounded(.down)
        return Date(timeIntervalSince1970: (daysSinceEpoch - daysAgo) * daySeconds + hour * 3600)
    }

    private static func entry(
        id: String,
        practice: SpiritualPractice,
        notes: String,
        penance: String? = nil,
        daysAgo: Double,
        hour: Double = 8
    ) -> PrivateDiaryCheckInEntry {
        PrivateDiaryCheckInEntry(
            id: id,
            practice: practice,
            reflectionOrNotes: notes,
            confessorOrPenanceNotes: penance,
            createdAt: anchorDate(daysAgo: daysAgo, hour: hour)
        )
    }

    private static func confessionEntries() -> [PrivateDiaryCheckInEntry] {
        [
            entry(
                id: "seed-confession-1", practice: .confession,
                notes: "Exame sincero: julgamentos temerários e apego aos próprios projetos. Alívio e paz reconquistada.",
                penance: "Rezar o Salmo 50 e oferecer uma dezena pelas famílias.",
                daysAgo: 2, hour: 17
            ),
            entry(
                id: "seed-confession-2", practice: .confession,
                notes: "Confissão quinzenal: falta de paciência com liderados e omissões na oração ao entardecer.",
                penance: "Mortificar a crítica no trabalho e rezar pelos superiores antes das reuniões difíceis.",
                daysAgo: 16, hour: 18
            ),
            entry(
                id: "seed-confession-3", practice: .confession,
                notes: "Direção espiritual: frieza diante do cansaço e hesitação na generosidade de tempo com os irmãos.",
                penance: "Cinco minutos de silêncio de joelhos aos pés da cruz ao regressar ao lar.",
                daysAgo: 28, hour: 19
            )
        ]
    }

    private static func lectioDivinaEntries() -> [PrivateDiaryCheckInEntry] {
        [
            entry(
                id: "seed-lectio-beatitudes", practice: .dailyGospel,
                notes: "Mt 5, 3: 'Bem-aventurados os pobres em espírito'. Reconhecer a própria pequenez diante de Deus e esvaziar o coração.",
                daysAgo: 4, hour: 6
            ),
            entry(
                id: "seed-lectio-samaritan", practice: .dailyGospel,
                notes: "Lc 10, 33: O Bom Samaritano cuidou das feridas. Senhor, dá-me olhos atentos aos caídos ao meu lado hoje.",
                daysAgo: 11, hour: 7
            ),
            entry(
                id: "seed-lectio-prodigal", practice: .dailyGospel,
                notes: "Lc 15, 20: 'Quando ainda estava longe, o pai o viu e correu ao seu encontro'. Jamais duvidar do abraço de Deus.",
                daysAgo: 18, hour: 7
            ),
            entry(
                id: "seed-lectio-vine", practice: .dailyGospel,
                notes: "Jo 15, 5: 'Sem mim nada podeis fazer'. O fruto espiritual vem de permanecer intimamente enxertado na Videira.",
                daysAgo: 25, hour: 6
            )
        ]
    }

    private static func mentalPrayerEntries() -> [PrivateDiaryCheckInEntry] {
        [
            entry(
                id: "seed-prayer-silence", practice: .mentalPrayer,
                notes: "15 min de silêncio na presença do Senhor. Resolução do dia: calar prontamente diante de qualquer contradição no trabalho.",
                daysAgo: 1, hour: 7
            ),
            entry(
                id: "seed-prayer-consolation", practice: .mentalPrayer,
                notes: "Oração da manhã fecunda em consolações. Certeza viva da filiação divina e profunda gratidão pela providência diária.",
                daysAgo: 7, hour: 7
            ),
            entry(
                id: "seed-prayer-aridity", practice: .mentalPrayer,
                notes: "Aridez sensível e mente dispersa. Perseverar no deserto: amar a Deus sem buscar o agrado próprio de sentir sua presença.",
                daysAgo: 14, hour: 6
            ),
            entry(
                id: "seed-prayer-resolution", practice: .mentalPrayer,
                notes: "Meditação na Paixão de Cristo. Resolução: suportar as dores de cabeça e a rotina pesada sem queixas exteriores.",
                daysAgo: 22, hour: 7
            )
        ]
    }

    private static func liturgicalDevotionEntries() -> [PrivateDiaryCheckInEntry] {
        [
            entry(
                id: "seed-mass-communion", practice: .holyMass,
                notes: "Santa Missa paroquial. Ação de graças na comunhão: 'Senhor Jesus, consumi o meu egoísmo no Vosso amor infinito'.",
                daysAgo: 3, hour: 8
            ),
            entry(
                id: "seed-adoration-sacrario", practice: .adoration,
                notes: "Hora Santa diante do Santíssimo Sacramento. Fruto da adoração: paz interior e serenidade nas decisões da semana.",
                daysAgo: 8, hour: 19
            ),
            entry(
                id: "seed-reading-cruz", practice: .spiritualReading,
                notes: "Subida do Monte Carmelo — São João da Cruz: 'Para vir a saber tudo, não queiras saber algo em nada'. Desapego interior.",
                daysAgo: 13, hour: 21
            ),
            entry(
                id: "seed-reading-augustine", practice: .spiritualReading,
                notes: "Confissões — Santo Agostinho: 'Tarde te amei, ó Beleza tão antiga e tão nova! Eis que habitavas dentro de mim e eu fora'.",
                daysAgo: 20, hour: 21
            ),
            entry(
                id: "seed-reading-faustina", practice: .spiritualReading,
                notes: "Diário — Santa Faustina: 'Quanto maior a miséria da alma, tanto maior é o direito à Minha misericórdia'. Jesus, eu confio em Vós.",
                daysAgo: 27, hour: 21
            )
        ]
    }
}
