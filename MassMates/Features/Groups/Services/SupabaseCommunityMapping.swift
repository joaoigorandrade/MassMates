import Foundation

/// Maps the `jsonb` payloads of the Supabase RPCs onto the domain models.
enum SupabaseCommunityMapping {
    // MARK: - Body / Public API
    static func group(
        from json: JSONValue,
        memberCount: Int = 0,
        isFeatured: Bool = false,
        sponsorName: String? = nil,
        sponsorCoupon: String? = nil
    ) -> CommunityGroup {
        let object = json.objectValue ?? [:]
        let goalTarget = object["goal_target"]?.intValue ?? 0
        let role = object["role"]?.stringValue
        return CommunityGroup(
            id: object["id"]?.stringValue ?? "",
            name: object["name"]?.stringValue ?? "Fraternidade",
            parishOrCommunity: communityLabel(from: object),
            inviteCode: object["invite_code"]?.stringValue ?? "",
            type: groupType(object["group_type"]?.stringValue),
            scoringMode: scoringMode(object["scoring_mode"]?.stringValue),
            sharingRequirement: sharingRequirement(object["sharing_requirement"]?.stringValue),
            memberCount: object["member_count"]?.intValue ?? memberCount,
            collectiveGoalProgress: 0,
            collectiveGoalLabel: goalLabel(target: goalTarget),
            isOfficialSeasonalChallenge: isFeatured || object["is_featured"]?.boolValue == true,
            sponsorName: sponsorName,
            sponsorCoupon: sponsorCoupon,
            startsOn: localDate(from: object["starts_on"]?.stringValue),
            endsOn: localDate(from: object["ends_on"]?.stringValue),
            isCurrentUserAdmin: role == "admin"
        )
    }

    /// A `yyyy-MM-dd` date of the server, read in the **current** calendar.
    static func localDate(from raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }

    static func groupType(_ raw: String?) -> CommunityGroupType {
        switch raw {
        case "challenge": return .challenge
        default: return .fraternity
        }
    }

    static func scoringMode(_ raw: String?) -> GroupScoringMode {
        switch raw {
        case "collective_treasure": return .collectiveTreasure
        case "custom_points": return .customPoints
        default: return .faithfulDays
        }
    }

    static func sharingRequirement(_ raw: String?) -> GroupSharingRequirement {
        switch raw {
        case "written_fruit": return .writtenFruit
        case "photo_witness": return .photoWitness
        default: return .openHonor
        }
    }

    static func practice(_ raw: String?) -> SpiritualPractice {
        switch raw {
        case "holy_mass": return .holyMass
        case "daily_gospel": return .dailyGospel
        case "mental_prayer": return .mentalPrayer
        case "spiritual_reading": return .spiritualReading
        case "rosary": return .rosary
        case "adoration": return .adoration
        case "fasting": return .fasting
        case "confession": return .confession
        default: return .rosary
        }
    }

    static func backendPractice(_ practice: SpiritualPractice) -> String {
        switch practice {
        case .rosary: return "rosary"
        case .holyMass: return "holy_mass"
        case .dailyGospel: return "daily_gospel"
        case .adoration: return "adoration"
        case .mentalPrayer: return "mental_prayer"
        case .spiritualReading: return "spiritual_reading"
        case .fasting: return "fasting"
        case .confession: return "confession"
        }
    }

    static func initials(for name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init)
        return letters.isEmpty ? "—" : letters.joined().uppercased()
    }

    static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        return ISO8601DateFormatter().date(from: raw)
    }

    static func relativeTimeLabel(from raw: String?) -> String {
        guard let date = parseDate(raw) else { return "" }
        return GroupFeedComment.relativeTime(from: date)
    }

    static func displayNameMap(from rows: [JSONValue]) -> [String: String] {
        var names: [String: String] = [:]
        for row in rows {
            guard let id = row["id"]?.stringValue else { continue }
            names[id] = row["display_name"]?.stringValue ?? "Irmão"
        }
        return names
    }

    static func liturgicalDay(from json: JSONValue) -> LiturgicalDaySummary {
        let object = json.objectValue ?? [:]
        let date = object["date"]?.stringValue ?? object["calendar_date"]?.stringValue ?? ""
        let saints = (object["saints"]?.arrayValue ?? []).compactMap { item in
            item.stringValue ?? item["name"]?.stringValue
        }
        return LiturgicalDaySummary(
            id: date,
            date: date,
            season: object["season"]?.stringValue,
            liturgicalColor: object["liturgical_color"]?.stringValue,
            celebration: object["celebration"]?.stringValue,
            rank: object["rank"]?.stringValue,
            saints: saints
        )
    }

    // MARK: - Subviews / Private Helpers
    private static func communityLabel(from object: [String: JSONValue]) -> String {
        let description = object["description"]?.stringValue ?? ""
        let preview = object["description_preview"]?.stringValue ?? description
        let trimmed = preview.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Comunidade Fraterna" : trimmed
    }

    private static func goalLabel(target: Int) -> String {
        target > 0 ? "Meta de \(target) pontos" : "Meta Fraterna"
    }
}
