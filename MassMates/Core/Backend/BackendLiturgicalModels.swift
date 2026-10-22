import Foundation

/// One day of the liturgical calendar, as the A7 RPCs return it.
struct LiturgicalDaySummary: Sendable, Equatable, Codable, Identifiable {
    let id: String
    let date: String
    let season: String?
    let liturgicalColor: String?
    let celebration: String?
    let rank: String?
    let saints: [String]

    var color: LiturgicalColor {
        switch liturgicalColor {
        case "purple": return .purple
        case "white": return .white
        case "red": return .red
        case "rose": return .rose
        default: return .green
        }
    }
}

/// The Today payload of A7: the day, its readings and its saints.
struct TodayLiturgySummary: Sendable, Equatable {
    let date: String
    let day: LiturgicalDaySummary?
    let readings: JSONValue?
    let saints: [String]
}
