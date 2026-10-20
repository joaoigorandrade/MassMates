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
            title: "1º Mistério: A Anunciação do Anjo a Maria",
            fruitOfMystery: "Fruto do mistério: A humildade",
            meditation: "Eis aqui a serva do Senhor; faça-se em mim segundo a tua palavra."
        ),
        RosaryDecade(
            number: 2,
            title: "2º Mistério: A Visitação de Maria a Santa Isabel",
            fruitOfMystery: "Fruto do mistério: A caridade fraterna",
            meditation: "Maria pôs-se a caminho e foi apressadamente às montanhas da Judeia."
        ),
        RosaryDecade(
            number: 3,
            title: "3º Mistério: O Nascimento de Jesus em Belém",
            fruitOfMystery: "Fruto do mistério: O desprendimento e a pobreza espiritual",
            meditation: "Ela deu à luz o seu filho primogênito, envolveu-o em faixas e deitou-o numa manjedoura."
        ),
        RosaryDecade(
            number: 4,
            title: "4º Mistério: A Apresentação do Menino Jesus no Templo",
            fruitOfMystery: "Fruto do mistério: A obediência e a pureza",
            meditation: "Meus olhos viram a tua salvação, luz para iluminar as nações."
        ),
        RosaryDecade(
            number: 5,
            title: "5º Mistério: O Encontro do Menino Jesus no Templo",
            fruitOfMystery: "Fruto do mistério: A busca constante de Deus",
            meditation: "Não sabíeis que devo ocupar-me das coisas de meu Pai?"
        ),
    ]

    static let luminousDecades: [RosaryDecade] = [
        RosaryDecade(
            number: 1,
            title: "1º Mistério: O Batismo de Jesus no Rio Jordão",
            fruitOfMystery: "Fruto do mistério: A fidelidade às promessas do Batismo",
            meditation: "Este é o meu Filho amado, em quem ponho o meu bem-querer."
        ),
        RosaryDecade(
            number: 2,
            title: "2º Mistério: A Autorrevelação nas Bodas de Caná",
            fruitOfMystery: "Fruto do mistério: A confiança por meio de Maria",
            meditation: "Fazei tudo o que ele vos disser."
        ),
        RosaryDecade(
            number: 3,
            title: "3º Mistério: O Anúncio do Reino de Deus",
            fruitOfMystery: "Fruto do mistério: A conversão do coração",
            meditation: "Completou-se o tempo e o Reino de Deus está próximo; convertei-vos."
        ),
        RosaryDecade(
            number: 4,
            title: "4º Mistério: A Transfiguração do Senhor",
            fruitOfMystery: "Fruto do mistério: O desejo de santidade",
            meditation: "Seu rosto brilhou como o sol e suas vestes tornaram-se brancas como a luz."
        ),
        RosaryDecade(
            number: 5,
            title: "5º Mistério: A Instituição da Santíssima Eucaristia",
            fruitOfMystery: "Fruto do mistério: O amor e a adoração à Eucaristia",
            meditation: "Isto é o meu corpo, que é dado por vós; fazei isto em memória de mim."
        ),
    ]

    static let sorrowfulDecades: [RosaryDecade] = [
        RosaryDecade(
            number: 1,
            title: "1º Mistério: A Agonia de Jesus no Horto das Oliveiras",
            fruitOfMystery: "Fruto do mistério: A contrição dos pecados",
            meditation: "Pai, se queres, afasta de mim este cálice; contudo, não se faça a minha vontade, mas a tua."
        ),
        RosaryDecade(
            number: 2,
            title: "2º Mistério: A Flagelação do Senhor",
            fruitOfMystery: "Fruto do mistério: A mortificação dos sentidos",
            meditation: "Ele foi ferido por causa de nossas transgressões, pelas suas chagas fomos curados."
        ),
        RosaryDecade(
            number: 3,
            title: "3º Mistério: A Coroação de Espinhos",
            fruitOfMystery: "Fruto do mistério: O desapego da soberba",
            meditation: "Teceram uma coroa de espinhos e puseram-na sobre a sua cabeça."
        ),
        RosaryDecade(
            number: 4,
            title: "4º Mistério: Jesus Carrega a Cruz até o Calvário",
            fruitOfMystery: "Fruto do mistério: A paciência nas provações",
            meditation: "Se alguém quer vir após mim, renuncie a si mesmo, tome a sua cruz a cada dia e siga-me."
        ),
        RosaryDecade(
            number: 5,
            title: "5º Mistério: A Crucificação e Morte de Jesus",
            fruitOfMystery: "Fruto do mistério: A perseverança final e o amor aos inimigos",
            meditation: "Pai, nas tuas mãos entrego o meu espírito."
        ),
    ]

    static let gloriousDecades: [RosaryDecade] = [
        RosaryDecade(
            number: 1,
            title: "1º Mistério: A Ressurreição de Nosso Senhor",
            fruitOfMystery: "Fruto do mistério: A fé viva",
            meditation: "Por que buscais entre os mortos aquele que está vivo? Não está aqui, mas ressuscitou."
        ),
        RosaryDecade(
            number: 2,
            title: "2º Mistério: A Ascensão de Jesus ao Céu",
            fruitOfMystery: "Fruto do mistério: A esperança cristã",
            meditation: "Enquanto os abençoava, afastou-se deles e foi elevado ao céu."
        ),
        RosaryDecade(
            number: 3,
            title: "3º Mistério: A Descida do Espírito Santo em Pentecostes",
            fruitOfMystery: "Fruto do mistério: A sabedoria e o zelo apostólico",
            meditation: "Todos ficaram cheios do Espírito Santo e começaram a anunciar as maravilhas de Deus."
        ),
        RosaryDecade(
            number: 4,
            title: "4º Mistério: A Assunção de Nossa Senhora ao Céu",
            fruitOfMystery: "Fruto do mistério: A graça de uma santa morte",
            meditation: "O Todo-Poderoso fez em mim maravilhas, e santo é o seu nome."
        ),
        RosaryDecade(
            number: 5,
            title: "5º Mistério: A Coroação de Maria como Rainha do Céu e da Terra",
            fruitOfMystery: "Fruto do mistério: A devoção filial à Virgem Maria",
            meditation: "Apareceu no céu um grande sinal: uma Mulher vestida de sol, com uma coroa de doze estrelas."
        ),
    ]
}
