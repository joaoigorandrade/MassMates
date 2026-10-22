import Foundation

/// The validation of the creation form. A **fraternity** has no window; a
/// **dated challenge** must declare a start and an end, with the end after
/// the start and a length between 1 and 365 days.
extension GroupCreationDraft {
    // MARK: - Body / Public API
    /// The message the form shows, or `nil` when the draft is valid.
    var challengeWindowErrorMessage: String? {
        guard type == .challenge else { return nil }
        guard let startsOn, let endsOn else {
            return "Defina a data de início e a data de fim do desafio."
        }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startsOn)
        let endDay = calendar.startOfDay(for: endsOn)
        guard endDay > startDay else {
            return "A data de fim deve ser depois da data de início."
        }
        let length = GroupCreationDraft.dayCount(from: startDay, to: endDay)
        guard length <= GroupCreationDraft.maximumChallengeLengthInDays else {
            return "O desafio pode durar no máximo \(GroupCreationDraft.maximumChallengeLengthInDays) dias."
        }
        return nil
    }

    /// Applies the default window of a dated challenge (today → today + 40).
    mutating func applyChallengeWindowDefaults() {
        guard type == .challenge else {
            startsOn = nil
            endsOn = nil
            return
        }
        let start = startsOn ?? Date()
        startsOn = start
        endsOn = GroupCreationDraft.defaultEndDate(from: start)
    }

    /// A fraternity never carries a window; a challenge always does. Calling
    /// it after a type change resets the window to the defaults.
    mutating func normalizeWindowForType() {
        applyChallengeWindowDefaults()
    }

    // MARK: - Subviews / Private Helpers
}

/// The day count between two local midnights. It is computed on a **UTC**
/// calendar so a daylight-saving transition between the two dates cannot
/// shorten or lengthen the challenge by a day.
extension GroupCreationDraft {
    static func dayCount(from start: Date, to end: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
