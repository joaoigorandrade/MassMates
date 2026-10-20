import Foundation
import Networking

@MainActor
protocol CommunityLiveSyncing {
    func fetchLiveGroupPulse(groupId: String) async throws -> GroupLiveSyncPulse
    func pushCheckInSync(groupId: String, practice: SpiritualPractice) async throws -> GroupLiveSyncPulse
}

struct CheckInSyncPayload: Sendable, Equatable, Codable {
    let groupId: String
    let practice: String
}

struct LiveGroupPulseAPIRequest: APIRequest, Sendable {
    typealias Response = GroupLiveSyncPulse
    let request: any HTTPRequest
}

@MainActor
final class RemoteCommunitySyncService: CommunityLiveSyncing {
    // MARK: - Dependencies & State
    private let client: any NetworkClient

    // MARK: - Init
    init(
        client: any NetworkClient = URLSessionNetworkClient(
            baseURL: URLComponents(string: "https://api.massmates.app")?.url ?? URL(fileURLWithPath: "/"),
            logger: nil
        )
    ) {
        self.client = client
    }

    // MARK: - Body / Public API
    func fetchLiveGroupPulse(groupId: String) async throws -> GroupLiveSyncPulse {
        let httpRequest = HTTPRequestData(
            path: "/v1/groups/\(groupId)/pulse",
            method: .get
        )
        let apiRequest = LiveGroupPulseAPIRequest(request: httpRequest)
        return try await client.request(for: apiRequest)
    }

    func pushCheckInSync(groupId: String, practice: SpiritualPractice) async throws -> GroupLiveSyncPulse {
        let payload = CheckInSyncPayload(groupId: groupId, practice: practice.rawValue)
        let httpRequest = try HTTPRequestData(
            path: "/v1/groups/\(groupId)/check-ins",
            method: .post
        ).jsonBody(payload)
        let apiRequest = LiveGroupPulseAPIRequest(request: httpRequest)
        return try await client.request(for: apiRequest)
    }

    // MARK: - Subviews / Private Helpers
}
