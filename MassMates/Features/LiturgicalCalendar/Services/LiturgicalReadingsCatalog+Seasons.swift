import Foundation

extension LiturgicalReadingsCatalog {
    // MARK: - Dependencies & State

    // MARK: - Init

    // MARK: - Body / Public API
    static var lentReading: DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-lent",
            liturgicalDateLabel: "Quaresma • Quarta-feira de Cinzas",
            dateHeaderLabel: "Quarta-feira de Cinzas",
            firstReadingReference: "Jl 2, 12-18",
            firstReadingTitle: "Leitura do Livro do Profeta Joel",
            firstReadingText: "“Voltai para mim de todo o vosso coração, com jejuns, lágrimas e gemidos; rasgai o vosso coração e não as vossas vestes”, diz o Senhor Deus misericordioso e compassivo, paciente e rico em bondade.",
            psalmReference: "Salmo Responsorial (Sl 50)",
            psalmRefrain: "R. Misericórdia, ó Senhor, pois pecamos!",
            psalmVerses: "Lavai-me de minha iniqüidade e purificai-me do meu pecado. Criai em mim, ó Deus, um coração puro e renovai em mim um espírito decidido. Não me repilais da vossa presença.",
            gospelReference: "Mt 6, 1-6. 16-18",
            gospelTitle: "Evangelho segundo São Mateus",
            gospelText: "Naquele tempo, disse Jesus: “Ficai atentos para não praticar a vossa justiça na frente dos homens... Quando deres esmola, não saiba a esquerda o que faz a direita. Quando orares, ora a teu Pai em segredo. Quando jejuardes, perfuma a cabeça e lava o rosto”.",
            gospelCalloutQuote: "“E o teu Pai, que vê no segredo, te recompensará.”",
            lectioSteps: makeLectioSteps(
                lectio: "Jesus adverte contra a hipocrisia religiosa e propõe a oração, o jejum e a esmola no recolhimento diante do Pai.",
                meditatio: "Busco aprovação humana ou a comunhão sincera com Deus? Que renúncia interior posso abraçar nesta Quaresma?",
                oratio: "“Senhor, purifica as intenções do meu coração. Concede-me a graça de uma conversão sincera e profunda.”",
                contemplatio: "Guardar o coração no silêncio e praticar uma caridade oculta, alegrando o coração do Pai.",
                attentionTitle: "Coração Rasgado",
                attentionBody: "A penitência quaresmal não é aparência exterior, mas retorno afetuoso aos braços de Deus."
            )
        )
    }

    static var easterReading: DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-easter",
            liturgicalDateLabel: "Tempo Pascal • Domingo da Ressurreição",
            dateHeaderLabel: "Domingo de Páscoa da Ressurreição",
            firstReadingReference: "At 10, 34a. 37-43",
            firstReadingTitle: "Leitura dos Atos dos Apóstolos",
            firstReadingText: "Naqueles dias, Pedro disse: “Vós sabeis como Deus ungiu com o Espírito Santo a Jesus de Nazaré. Eles o mataram numa cruz. Mas Deus o ressuscitou no terceiro dia e permitiu que ele se manifestasse às testemunhas”.",
            psalmReference: "Salmo Responsorial (Sl 117)",
            psalmRefrain: "R. Este é o dia que o Senhor fez: para nós alegria e júbilo!",
            psalmVerses: "Dai graças ao Senhor, porque ele é bom, o seu amor dura para sempre. A pedra que os pedreiros rejeitaram tornou-se a pedra angular. Isto é maravilhoso aos nossos olhos.",
            gospelReference: "Jo 20, 1-9",
            gospelTitle: "Evangelho segundo São João",
            gospelText: "No primeiro dia da semana, Maria Madalena foi ao túmulo de madrugada e viu a pedra retirada. Pedro e o outro discípulo correram ao sepulcro. O outro discípulo chegou primeiro, entrou, viu e acreditou.",
            gospelCalloutQuote: "“Ele entrou, viu e acreditou. Pois ainda não haviam compreendido a Escritura.”",
            lectioSteps: makeLectioSteps(
                lectio: "Na alvorada pascal, o amor impulsiona os discípulos ao sepulcro vazio. Os sinais visíveis abrem os olhos da fé para a vitória de Cristo sobre a morte.",
                meditatio: "Em que áreas da minha vida preciso deixar a luz da Ressurreição dissipar o medo e a desesperança?",
                oratio: "“Senhor Jesus Ressuscitado, Tu venceste a morte. Renova a minha fé e enche minha alma da Tua paz pascal.”",
                contemplatio: "Permanecer no júbilo da vitória de Cristo, irradiando serenidade e esperança para as pessoas ao meu redor.",
                attentionTitle: "A Fé Pascal",
                attentionBody: "O sepulcro vazio não é ausência, mas testemunho luminoso da vida eterna conquistada por Cristo."
            )
        )
    }

    static var adventReading: DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-advent",
            liturgicalDateLabel: "Tempo do Advento • I Domingo do Advento",
            dateHeaderLabel: "I Domingo do Advento",
            firstReadingReference: "Is 2, 1-5",
            firstReadingTitle: "Leitura do Livro do Profeta Isaías",
            firstReadingText: "Nos últimos dias, o monte da casa do Senhor estará firme sobre os cumes. De suas espadas forjarão arados e de suas lanças foices. Vinde, caminhemos à luz do Senhor!",
            psalmReference: "Salmo Responsorial (Sl 121)",
            psalmRefrain: "R. Que alegria quando me disseram: “Vamos à casa do Senhor!”",
            psalmVerses: "Que alegria quando me disseram: Vamos à casa do Senhor! Nossos passos já pisam tuas portas, ó Jerusalém! Por amor de meus irmãos, peço a tua paz!",
            gospelReference: "Mt 24, 37-44",
            gospelTitle: "Evangelho segundo São Mateus",
            gospelText: "Naquele tempo, disse Jesus: “Como foi nos dias de Noé, assim será na vinda do Filho do Homem. Ficai atentos, porque não sabeis em que dia virá o vosso Senhor. Ficai preparados!”",
            gospelCalloutQuote: "“Ficai preparados! Porque, na hora em que menos pensais, o Filho do Homem virá.”",
            lectioSteps: makeLectioSteps(
                lectio: "Jesus nos convida à vigilância serena e ativa. O Advento é a escola da santa espera pelo Senhor que vem.",
                meditatio: "Minha vida de oração está vigilante ou adormecida pelas distrações do mundo? O que preciso purificar para receber Jesus?",
                oratio: "“Vem, Senhor Jesus! Desperta o meu coração da tibieza e renova em mim o desejo sincero da Tua presença.”",
                contemplatio: "Cultivar a prontidão interior e a paciência nas pequenas contrariedades do dia a dia.",
                attentionTitle: "Vigiai e Orai",
                attentionBody: "A vigilância cristã é a postura confiante da noiva que aguarda com amor as bodas do Cordeiro."
            )
        )
    }

    static var aparecidaReading: DailyLiturgicalReading {
        DailyLiturgicalReading(
            id: "reading-aparecida",
            liturgicalDateLabel: "Solenidade • N. Sra. Aparecida, Padroeira do Brasil",
            dateHeaderLabel: "Sábado, 12 de Outubro",
            firstReadingReference: "Est 5, 1b-2; 7, 2b-3",
            firstReadingTitle: "Leitura do Livro de Ester",
            firstReadingText: "Ester apresentou-se ao rei. O rei estendeu para ela o cetro de ouro e disse: “Que tens, rainha Ester?” Ela respondeu: “Se encontrei graça a teus olhos, concede-me a vida e a vida do meu povo!”",
            psalmReference: "Salmo Responsorial (Sl 44)",
            psalmRefrain: "R. Escutai, minha filha, olhai: que o Rei se encante com vossa beleza!",
            psalmVerses: "Ouve, filha, e vê, inclina teu ouvido: esquece o teu povo e a casa paterna. O Rei se encantará com a tua beleza; ele é teu Senhor, presta-lhe homenagem.",
            gospelReference: "Jo 2, 1-11",
            gospelTitle: "Evangelho segundo São João",
            gospelText: "Houve um casamento em Caná da Galileia. A mãe de Jesus estava lá. Como o vinho acabasse, Maria disse a Jesus: “Eles não têm mais vinho”. E disse aos que serviam: “Fazei tudo o que ele vos disser”.",
            gospelCalloutQuote: "“Sua mãe disse aos que estavam servindo: ‘Fazei tudo o que ele vos disser’.”",
            lectioSteps: makeLectioSteps(
                lectio: "Nas bodas de Caná, Maria intercede com solicitude maternal e aponta o caminho seguro: obedecer à Palavra de Jesus.",
                meditatio: "Apresento a Maria as necessidades e angústias da minha família? Tenho a prontidão de fazer o que Jesus me pede?",
                oratio: "“Nossa Senhora Aparecida, Mãe e Padroeira do Brasil, rogai por nós e ensinai-nos a fazer tudo o que Jesus disser.”",
                contemplatio: "Consagrar o dia sob o manto de Nossa Senhora, renovando o compromisso de fidelidade ao Evangelho.",
                attentionTitle: "Fazei Tudo o que Ele Disser",
                attentionBody: "O coração de Maria conduz sempre ao Coração de Jesus; Sua intercessão antecipa a hora da graça."
            )
        )
    }

    // MARK: - Subviews / Private Helpers
}
