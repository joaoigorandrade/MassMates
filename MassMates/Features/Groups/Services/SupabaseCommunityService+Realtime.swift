import Foundation

extension SupabaseCommunityService: CommunityRealtimeStreaming {
    // MARK: - Body / Public API
    func changes(for table: RealtimeTable) -> AsyncThrowingStream<RealtimeChange, Error> {
        guard let realtime else {
            return AsyncThrowingStream { $0.finish() }
        }
        return realtime.events(table: table.rawValue)
    }

    func startListening() async {
        guard let realtime else { return }
        try? await realtime.connect()
        for table in RealtimeTable.allCases {
            try? await realtime.subscribe(table: table.rawValue)
        }
    }

    func stopListening() async {
        await realtime?.close()
    }

    // MARK: - Subviews / Private Helpers
}
