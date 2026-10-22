import Foundation
import Testing
@testable import MassMates

/// The `massmates://` scheme must resolve **both** documented links: the
/// invite deep link and the GoTrue auth callback.
struct DeepLinkRoutingTests {
    // MARK: - Body / Public API
    @Test("The invite deep link resolves to the join-group route")
    func inviteLinkResolvesToTheJoinRoute() throws {
        let url = try #require(URL(string: "massmates://join/ST1925"))
        let route = try #require(AppRoute.route(from: url))
        #expect(route == .createJoinGroup(
            initialTab: .joinByCode,
            prefilledInviteCode: "ST1925",
            season: .green
        ))
    }

    @Test("The auth callback resolves to the authentication route and carries the credentials")
    func authCallbackResolvesToTheAuthenticationRoute() throws {
        let url = try #require(URL(string: "massmates://auth/callback?token=123456&email=fiel@paroquia.app&type=email"))
        let route = try #require(AppRoute.route(from: url))

        guard case .authenticationCallback(let payload, _) = route else {
            Issue.record("Expected the auth callback to resolve to the authentication route")
            return
        }
        #expect(payload.token == "123456")
        #expect(payload.email == "fiel@paroquia.app")
        #expect(payload.type == "email")
        #expect(payload.carriesCredentials)
    }

    @Test("The auth callback also reads the credentials from the URL fragment")
    func authCallbackReadsTheFragment() throws {
        let url = try #require(URL(string: "massmates://auth/callback#access_token=at&refresh_token=rt"))
        let payload = try #require(AuthCallbackPayload(url: url))
        #expect(payload.accessToken == "at")
        #expect(payload.refreshToken == "rt")
        #expect(payload.carriesCredentials)
    }

    @Test("A link that is neither an invite nor an auth callback resolves to nothing")
    func unknownLinkResolvesToNothing() throws {
        let url = try #require(URL(string: "massmates://today"))
        #expect(AppRoute.route(from: url) == nil)
    }

    // MARK: - Subviews / Private Helpers
}
