import Foundation

/// The liturgical content of A7. The Today header and the calendar read the
/// server-seeded content instead of the local catalog.
extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func todayLiturgy() async throws -> TodayLiturgySummary {
        let response = try await postgrest.callRPC("get_today_liturgy", payload: [:])
        let day = response["day"].map { SupabaseCommunityMapping.liturgicalDay(from: $0) }
        let saints = (response["saints"]?.arrayValue ?? []).compactMap { $0["name"]?.stringValue }
        return TodayLiturgySummary(
            date: response["date"]?.stringValue ?? "",
            day: day,
            readings: response["readings"],
            saints: saints
        )
    }

    func liturgicalCalendar(year: Int) async throws -> [LiturgicalDaySummary] {
        let response = try await postgrest.callRPC("get_liturgical_calendar", payload: [
            "p_year": .int(year)
        ])
        let days = response["days"]?.arrayValue ?? response.arrayValue ?? []
        return days.map { SupabaseCommunityMapping.liturgicalDay(from: $0) }
    }

    // MARK: - Subviews / Private Helpers
}
