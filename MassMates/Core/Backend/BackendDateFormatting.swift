import Foundation

/// The date format the Postgres `date` type expects.
enum BackendDateFormatting {
    // MARK: - Body / Public API
    /// The `yyyy-MM-dd` representation of a date **in the current calendar and
    /// timezone** — not in UTC. A check-in made at 22h in São Paulo belongs to
    /// the local day, and the server compares `local_date` against the user's
    /// own day, so the client must not shift the day across the date line.
    static func localDayString(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    // MARK: - Subviews / Private Helpers
}
