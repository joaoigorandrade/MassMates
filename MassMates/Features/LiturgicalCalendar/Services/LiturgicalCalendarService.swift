import Foundation

protocol LiturgicalCalendarProviding: Sendable {
    func liturgicalDay(for date: Date) -> LiturgicalDay
}

struct DefaultLiturgicalCalendarService: LiturgicalCalendarProviding {
    // MARK: - Init
    init() {}

    // MARK: - Public API
    func liturgicalDay(for date: Date) -> LiturgicalDay {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let season = resolveSeason(for: date, calendar: calendar)
        return LiturgicalDay(
            season: season,
            color: season.liturgicalColor,
            seasonTitle: season.title,
            saintOrFeast: resolveSaintOrFeast(for: date, season: season, calendar: calendar),
            reading: defaultReading(for: season)
        )
    }

    // MARK: - Private Helpers
    private func resolveSeason(for date: Date, calendar: Calendar) -> LiturgicalSeason {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        if (month == 12 && day >= 25) || (month == 1 && day <= 6) {
            return .christmas
        }
        if let easterSeason = resolveEasterCycle(for: date, year: year, calendar: calendar) {
            return easterSeason
        }
        if let adventSeason = resolveAdventCycle(for: date, year: year, calendar: calendar) {
            return adventSeason
        }
        return .ordinaryTime
    }

    private func resolveEasterCycle(for date: Date, year: Int, calendar: Calendar) -> LiturgicalSeason? {
        let easter = Self.easterSunday(year: year, calendar: calendar)
        let startOfDate = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: easter, to: startOfDate).day ?? 0
        if diff == -2 || diff == -7 || diff == 49 {
            return .pentecost
        }
        if diff == -21 {
            return .laetare
        }
        if diff >= -46 && diff < 0 {
            return .lent
        }
        if diff >= 0 && diff < 49 {
            return .easter
        }
        return nil
    }

    private func resolveAdventCycle(for date: Date, year: Int, calendar: Calendar) -> LiturgicalSeason? {
        guard let christmas = calendar.date(from: DateComponents(year: year, month: 12, day: 25)) else {
            return nil
        }
        let weekday = calendar.component(.weekday, from: christmas)
        let daysToFourthSunday = weekday == 1 ? 7 : (weekday - 1)
        guard let adventStart = calendar.date(byAdding: .day, value: -(daysToFourthSunday + 21), to: christmas) else {
            return nil
        }
        let startOfDate = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: adventStart, to: startOfDate).day ?? -1
        if diff == 14 {
            return .gaudete
        }
        if diff >= 0 && startOfDate < christmas {
            return .advent
        }
        return nil
    }

    // Meeus/Jones/Butcher Gregorian Easter computus
    static func easterSunday(year: Int, calendar: Calendar) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func resolveSaintOrFeast(for date: Date, season: LiturgicalSeason, calendar: Calendar) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        switch (month, day) {
        case (10, 12): return "Nossa Senhora da Conceição Aparecida, Padroeira do Brasil"
        case (8, 11), (8, 14): return "Santa Clara de Assis, Virgem"
        case (3, 19): return "São José, Esposo da Virgem Maria"
        case (6, 24): return "Natividade de São João Batista"
        default: return "Santa Clara de Assis, Virgem"
        }
    }

    private func defaultReading(for season: LiturgicalSeason) -> DailyLiturgicalReading {
        LiturgicalReadingsCatalog.reading(for: season)
    }
}
