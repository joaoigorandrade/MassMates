import ActivityKit
import Foundation

struct PrayerLiveActivityAttributes: ActivityAttributes {
    // MARK: - Dependencies & State
    public struct ContentState: Codable, Hashable, Sendable {
        public var remainingSeconds: Int
        public var progress: Double
        public var currentBeadLabel: String
        public var isRunning: Bool

        public init(
            remainingSeconds: Int,
            progress: Double,
            currentBeadLabel: String,
            isRunning: Bool
        ) {
            self.remainingSeconds = remainingSeconds
            self.progress = progress
            self.currentBeadLabel = currentBeadLabel
            self.isRunning = isRunning
        }
    }

    public var title: String
    public var seasonName: String

    // MARK: - Init
    public init(title: String, seasonName: String = "Tempo Comum") {
        self.title = title
        self.seasonName = seasonName
    }

    // MARK: - Body / Public API
    // MARK: - Subviews / Private Helpers
}
