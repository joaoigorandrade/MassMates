import Foundation

enum RosaryCatalog {
    static func decades(for mysterySet: RosaryMysterySet) -> [RosaryDecade] {
        switch mysterySet {
        case .joyful: joyfulDecades
        case .luminous: luminousDecades
        case .sorrowful: sorrowfulDecades
        case .glorious: gloriousDecades
        }
    }

    static let joyfulDecades: [RosaryDecade] = [
        RosaryDecade(
            number: 1,
            title: "A Anunciação do Arcanjo Gabriel a Maria",
            fruitOfMystery: "Fruto do mistério: A humildade e obediência filial",
            meditation: "«Eis aqui a serva do Senhor; faça-se em mim segundo a tua palavra.»",
            scriptureReference: "Lucas 1, 38"
        ),
        RosaryDecade(
            number: 2,
            title: "A Visitação de Nossa Senhora a Santa Isabel",
            fruitOfMystery: "Fruto do mistério: A caridade fraterna e prontidão no serviço",
            meditation: "«Bendita és tu entre as mulheres e bendito é o fruto do teu ventre!»",
            scriptureReference: "Lucas 1, 42"
        ),
        RosaryDecade(
            number: 3,
            title: "O Nascimento de Jesus no Presépio de Belém",
            fruitOfMystery: "Fruto do mistério: O desprendimento e a pobreza evangélica",
            meditation: "«Deu à luz o seu primogênito, envolveu-o em faixas e deitou-o numa manjedoura.»",
            scriptureReference: "Lucas 2, 7"
        ),
        RosaryDecade(
            number: 4,
            title: "A Apresentação do Menino Jesus no Templo",
            fruitOfMystery: "Fruto do mistério: A pureza interior e obediência à vontade divina",
            meditation: "«Meus olhos viram a tua salvação, luz para iluminar todas as nações.»",
            scriptureReference: "Lucas 2, 30-32"
        ),
        RosaryDecade(
            number: 5,
            title: "A Perda e Encontro do Menino Jesus no Templo",
            fruitOfMystery: "Fruto do mistério: A busca constante de Deus e fidelidade à vocação",
            meditation: "«Não sabíeis que devo ocupar-me das coisas de meu Pai?»",
            scriptureReference: "Lucas 2, 49"
        )
    ]

    static let luminousDecades: [RosaryDecade] = [
        RosaryDecade(
            number: 1,
            title: "O Batismo de Jesus no Rio Jordão",
            fruitOfMystery: "Fruto do mistério: A fidelidade às promessas batismais",
            meditation: "«Este é o meu Filho amado, em quem ponho o meu agrado. Escutai-o!»",
            scriptureReference: "Mateus 3, 17"
        ),
        RosaryDecade(
            number: 2,
            title: "A Autorrevelação de Jesus nas Bodas de Caná",
            fruitOfMystery: "Fruto do mistério: A confiança na intercessão da Virgem Maria",
            meditation: "«Fazei tudo o que ele vos disser.»",
            scriptureReference: "João 2, 5"
        ),
        RosaryDecade(
            number: 3,
            title: "O Anúncio do Reino de Deus e Convite à Conversão",
            fruitOfMystery: "Fruto do mistério: A contrição contínua e santidade de vida",
            meditation: "«O Reino de Deus está próximo; convertei-vos e crede no Evangelho.»",
            scriptureReference: "Marcos 1, 15"
        ),
        RosaryDecade(
            number: 4,
            title: "A Transfiguração do Senhor no Monte Tabor",
            fruitOfMystery: "Fruto do mistério: O desejo da contemplação e vida de oração",
            meditation: "«O seu rosto brilhou como o sol e as suas vestes tornaram-se alvas como a luz.»",
            scriptureReference: "Mateus 17, 2"
        ),
        RosaryDecade(
            number: 5,
            title: "A Instituição da Santíssima Eucaristia",
            fruitOfMystery: "Fruto do mistério: O amor ardente e adoração ao Santíssimo Sacramento",
            meditation: "«Isto é o meu corpo entregue por vós; fazei isto em memória de mim.»",
            scriptureReference: "Lucas 22, 19"
        )
    ]

    static let sorrowfulDecades: [RosaryDecade] = [
        RosaryDecade(
            number: 1,
            title: "A Agonia de Jesus no Horto das Oliveiras",
            fruitOfMystery: "Fruto do mistério: A dor sincera dos pecados e conformidade filial",
            meditation: "«Pai, se queres, afasta de mim este cálice; contudo, não se faça a minha vontade, mas a tua.»",
            scriptureReference: "Lucas 22, 42"
        ),
        RosaryDecade(
            number: 2,
            title: "A Flagelação Dolorosa de Nosso Senhor",
            fruitOfMystery: "Fruto do mistério: A mortificação dos sentidos e pureza cristã",
            meditation: "«Ele foi ferido por nossas transgressões e por suas chagas fomos curados.»",
            scriptureReference: "Isaías 53, 5"
        ),
        RosaryDecade(
            number: 3,
            title: "A Coroação de Espinhos de Nosso Senhor",
            fruitOfMystery: "Fruto do mistério: A humildade profunda e desapego da soberba",
            meditation: "«Teceram uma coroa de espinhos e puseram-na sobre a sua cabeça com zombaria.»",
            scriptureReference: "Marcos 15, 17"
        ),
        RosaryDecade(
            number: 4,
            title: "O Carregamento da Cruz até o Calvário",
            fruitOfMystery: "Fruto do mistério: A paciência nas tribulações e cruzes diárias",
            meditation: "«Se alguém quer vir após mim, renuncie a si mesmo, tome a sua cruz e siga-me.»",
            scriptureReference: "Lucas 9, 23"
        ),
        RosaryDecade(
            number: 5,
            title: "A Crucificação e Morte de Nosso Senhor",
            fruitOfMystery: "Fruto do mistério: A perseverança final e perdão aos inimigos",
            meditation: "«Pai, nas tuas mãos entrego o meu espírito... Tudo está consumado.»",
            scriptureReference: "Lucas 23, 46"
        )
    ]

    static let gloriousDecades: [RosaryDecade] = [
        RosaryDecade(
            number: 1,
            title: "A Ressurreição Gloriosa de Nosso Senhor",
            fruitOfMystery: "Fruto do mistério: A fé viva e a esperança na vida eterna",
            meditation: "«Buscais a Jesus de Nazaré, que foi crucificado? Ele ressuscitou, não está aqui!»",
            scriptureReference: "Marcos 16, 6"
        ),
        RosaryDecade(
            number: 2,
            title: "A Ascensão Admirável de Jesus aos Céus",
            fruitOfMystery: "Fruto do mistério: O anseio das moradas celestes e ardor apostólico",
            meditation: "«Enquanto os abençoava, elevou-se ao céu e sentou-se à direita de Deus.»",
            scriptureReference: "Lucas 24, 51"
        ),
        RosaryDecade(
            number: 3,
            title: "A Descida do Espírito Santo em Pentecostes",
            fruitOfMystery: "Fruto do mistério: A docilidade à graça e zelo pelas almas",
            meditation: "«Todos ficaram cheios do Espírito Santo e anunciavam com intrepidez a Palavra.»",
            scriptureReference: "Atos 2, 4"
        ),
        RosaryDecade(
            number: 4,
            title: "A Assunção Triunfal de Nossa Senhora aos Céus",
            fruitOfMystery: "Fruto do mistério: A pureza e a graça de uma santa morte",
            meditation: "«O Todo-Poderoso fez em mim maravilhas, e Santo é o seu nome.»",
            scriptureReference: "Lucas 1, 49"
        ),
        RosaryDecade(
            number: 5,
            title: "A Coroação de Maria como Rainha do Céu e da Terra",
            fruitOfMystery: "Fruto do mistério: A filial devoção à Santíssima Virgem",
            meditation: "«Apareceu no céu um grande sinal: uma Mulher vestida de sol, com doze estrelas.»",
            scriptureReference: "Apocalipse 12, 1"
        )
    ]
}
