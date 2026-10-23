import Foundation
import Testing
@testable import MassMates

struct LiturgicalReadingsCatalogTests {
    // MARK: - Dependencies & State

    // MARK: - Init

    // MARK: - Body / Public API
    @Test("All liturgical seasons return valid readings with complete 4-step Lectio Divina")
    func allSeasonsProvideCompleteLectioDivina() {
        for season in LiturgicalSeason.allCases {
            let reading = LiturgicalReadingsCatalog.reading(for: season)
            #expect(!reading.id.isEmpty)
            #expect(!reading.firstReadingReference.isEmpty)
            #expect(!reading.firstReadingText.isEmpty)
            #expect(!reading.psalmReference.isEmpty)
            #expect(!reading.psalmRefrain.isEmpty)
            #expect(!reading.psalmVerses.isEmpty)
            #expect(!reading.gospelReference.isEmpty)
            #expect(!reading.gospelText.isEmpty)
            #expect(!reading.gospelCalloutQuote.isEmpty)
            #expect(reading.lectioSteps.count == 4)

            let stages = reading.lectioSteps.map(\.stage)
            #expect(stages[0] == "1. Lectio")
            #expect(stages[1] == "2. Meditatio")
            #expect(stages[2] == "3. Oratio")
            #expect(stages[3] == "4. Contemplatio")
        }
    }

    @Test("Specific solemnity reading for Nossa Senhora Aparecida on October 12")
    func aparecidaSolemnityReading() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12)))

        let reading = LiturgicalReadingsCatalog.reading(for: .ordinaryTime, date: date)
        #expect(reading.id == "reading-aparecida")
        #expect(reading.gospelReference == "Jo 2, 1-11")
        #expect(reading.firstReadingReference == "Est 5, 1b-2; 7, 2b-3")

        let service = DefaultLiturgicalCalendarService()
        let day = service.liturgicalDay(for: date)
        #expect(day.reading.id == "reading-aparecida")
        #expect(day.saintOrFeast == "Nossa Senhora da Conceição Aparecida, Padroeira do Brasil")
    }

    @Test("Lent, Easter and Advent readings provide authentic scriptural references")
    func authenticSeasonalScripturalReferences() {
        let lent = LiturgicalReadingsCatalog.reading(for: .lent)
        #expect(lent.gospelReference == "Mt 6, 1-6. 16-18")
        #expect(lent.firstReadingReference == "Jl 2, 12-18")

        let easter = LiturgicalReadingsCatalog.reading(for: .easter)
        #expect(easter.gospelReference == "Jo 20, 1-9")
        #expect(easter.firstReadingReference == "At 10, 34a. 37-43")

        let advent = LiturgicalReadingsCatalog.reading(for: .advent)
        #expect(advent.gospelReference == "Mt 24, 37-44")
        #expect(advent.firstReadingReference == "Is 2, 1-5")
    }

    // MARK: - Subviews / Private Helpers
}
