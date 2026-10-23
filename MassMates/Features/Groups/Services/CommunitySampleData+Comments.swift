import Foundation

extension CommunitySampleData {
    static func sampleComments(for postId: String) -> [GroupFeedComment] {
        if postId.hasSuffix("post-1") || postId.hasSuffix("-1") {
            return commentsForPost1(postId: postId)
        } else if postId.hasSuffix("post-2") || postId.hasSuffix("-2") {
            return commentsForPost2(postId: postId)
        } else if postId.hasSuffix("post-3") || postId.hasSuffix("-3") {
            return commentsForPost3(postId: postId)
        } else if postId.hasSuffix("post-4") || postId.hasSuffix("-4") {
            return commentsForPost4(postId: postId)
        } else if postId.hasSuffix("post-5") || postId.hasSuffix("-5") {
            return commentsForPost5(postId: postId)
        } else if postId.hasSuffix("post-6") || postId.hasSuffix("-6") {
            return commentsForPost6(postId: postId)
        } else if postId.hasSuffix("post-7") || postId.hasSuffix("-7") {
            return commentsForPost7(postId: postId)
        } else if postId.hasSuffix("post-8") || postId.hasSuffix("-8") {
            return commentsForPost8(postId: postId)
        }
        return defaultComments(postId: postId)
    }

    private static func commentsForPost1(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-clara", "Clara Ribeiro"),
                        body: "Unidos em oração! Que Nossa Senhora interceda por cada lar da nossa paróquia.",
                        minutesAgo: 14, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-pe-lucas", "Pe. Lucas Mendes"),
                        body: "Deo gratias! “A família que reza unida permanece unida.” Rezando com você, Mateus.",
                        minutesAgo: 8, postId: postId),
            makeComment(id: "\(postId)-c3", author: ("user-gabriel", "Gabriel Santos"),
                        body: "Amém! Que belo fruto, meu irmão. Ofereci meu terço de hoje em comunhão.",
                        minutesAgo: 3, postId: postId)
        ]
    }

    private static func commentsForPost2(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-beatriz", "Beatriz Lima"),
                        body: "Que bela partilha! “Fazei tudo por amor; assim não há coisas pequenas.” — São Josemaría.",
                        minutesAgo: 32, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-helena", "Helena Costa"),
                        body: "Amém, Clara! “Permanecei em Mim” (Jo 15,4). Rezando pelas intenções da sua família.",
                        minutesAgo: 20, postId: postId),
            makeComment(id: "\(postId)-c3", author: ("user-rafael", "Rafael Oliveira"),
                        body: "Deo gratias! Essa passagem renovou minha esperança na oração da manhã.",
                        minutesAgo: 10, postId: postId)
        ]
    }

    private static func commentsForPost3(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-mateus", "Mateus Almeida"),
                        body: "Deo gratias, Padre! Louvado seja Deus pelo zelo pastoral com a nossa fraternidade.",
                        minutesAgo: 50, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-mariana", "Mariana Silva"),
                        body: "Amém! Que bênção começar o dia amparada pela graça do Santo Sacrifício.",
                        minutesAgo: 38, postId: postId),
            makeComment(id: "\(postId)-c3", author: ("user-clara", "Clara Ribeiro"),
                        body: "Unidos em oração ao Santo Altar! “A Santa Missa é o sol dos exercícios de piedade.”",
                        minutesAgo: 24, postId: postId),
            makeComment(id: "\(postId)-c4", author: ("user-teresa", "Dona Teresa"),
                        body: "Louvado seja Cristo! Rezando pela perseverança e ministério do senhor, Padre.",
                        minutesAgo: 11, postId: postId)
        ]
    }

    private static func commentsForPost4(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-pe-lucas", "Pe. Lucas Mendes"),
                        body: "“O tempo que passais com Jesus no Sacrário é o melhor tempo da terra.” — Sta. Teresa.",
                        minutesAgo: 95, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-gabriel", "Gabriel Santos"),
                        body: "Que testemunho inspirador! Que seu dia de trabalho seja fecundo e cheio de paz.",
                        minutesAgo: 65, postId: postId),
            makeComment(id: "\(postId)-c3", author: ("user-mariana", "Mariana Silva"),
                        body: "Unidos em oração diante de Jesus Eucarístico! O silêncio com o Senhor renova a alma.",
                        minutesAgo: 35, postId: postId)
        ]
    }

    private static func commentsForPost5(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-mateus", "Mateus Almeida"),
                        body: "Unidos no sacrifício silencioso! Que o Senhor fortaleça todos os nossos sacerdotes.",
                        minutesAgo: 140, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-clara", "Clara Ribeiro"),
                        body: "Deo gratias pela generosidade! A penitência fecunda as intenções de toda a Igreja.",
                        minutesAgo: 90, postId: postId),
            makeComment(id: "\(postId)-c3", author: ("user-teresa", "Dona Teresa"),
                        body: "Amém! Que bela partilha, rezando pelas intenções da sua família e perseverança.",
                        minutesAgo: 50, postId: postId)
        ]
    }

    private static func commentsForPost6(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-rafael", "Rafael Oliveira"),
                        body: "Constância serena! “Sê firme: amar é renovar continuamente a fidelidade.”",
                        minutesAgo: 200, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-helena", "Helena Costa"),
                        body: "Que bela partilha, rezando pelas intenções da sua família e pela sua perseverança!",
                        minutesAgo: 140, postId: postId),
            makeComment(id: "\(postId)-c3", author: ("user-pe-lucas", "Pe. Lucas Mendes"),
                        body: "Deo gratias! A fidelidade cotidiana nas pequenas coisas santifica a nossa caminhada.",
                        minutesAgo: 80, postId: postId)
        ]
    }

    private static func commentsForPost7(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-teresa", "Dona Teresa"),
                        body: "“Nada te perturbe, a paciência tudo alcança.” — Santa Teresa d'Ávila. Amém!",
                        minutesAgo: 240, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-clara", "Clara Ribeiro"),
                        body: "Que partilha oportuna! “Aprendei de mim, que sou manso e humilde de coração” (Mt 11,29).",
                        minutesAgo: 170, postId: postId),
            makeComment(id: "\(postId)-c3", author: ("user-mateus", "Mateus Almeida"),
                        body: "Deo gratias! Rezando para que o Senhor molde o nosso coração nessa mansidão.",
                        minutesAgo: 100, postId: postId)
        ]
    }

    private static func commentsForPost8(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-pe-lucas", "Pe. Lucas Mendes"),
                        body: "“Há júbilo no céu por um pecador que se arrepende.” (Lc 15,7). Deus seja louvado!",
                        minutesAgo: 300, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-clara", "Clara Ribeiro"),
                        body: "Que alegria na graça santificante! Unidos em oração, minha irmã.",
                        minutesAgo: 210, postId: postId)
        ]
    }

    private static func defaultComments(postId: String) -> [GroupFeedComment] {
        [
            makeComment(id: "\(postId)-c1", author: ("user-clara", "Clara Ribeiro"),
                        body: "Unidos em oração! Que bela partilha, rezando pelas intenções da sua família.",
                        minutesAgo: 10, postId: postId),
            makeComment(id: "\(postId)-c2", author: ("user-mateus", "Mateus Almeida"),
                        body: "Deo gratias! Amém, meu irmão. Firmeza e perseverança sempre na graça.",
                        minutesAgo: 4, postId: postId)
        ]
    }

    private static func makeComment(
        id: String,
        author: (id: String, name: String),
        body: String,
        minutesAgo: Double,
        postId: String
    ) -> GroupFeedComment {
        GroupFeedComment(
            id: id,
            authorId: author.id,
            authorDisplayName: author.name,
            body: body,
            createdAt: Date().addingTimeInterval(-minutesAgo * 60),
            isHidden: false,
            postId: postId
        )
    }
}
