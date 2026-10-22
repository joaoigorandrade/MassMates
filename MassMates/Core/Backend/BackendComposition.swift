import Foundation
import Networking

/// The composition root of the backend layer. It builds the whole object graph
/// once and hands it to the environment. Nothing here is a singleton: every
/// dependency is injected.
@MainActor
struct BackendComposition {
    // MARK: - Dependencies & State
    let config: SupabaseConfig
    let sessionStore: SupabaseSessionStore
    let authClient: SupabaseAuthClient
    let postgrest: SupabasePostgREST
    let storage: SupabaseStorageClient
    let realtime: SupabaseRealtimeClient
    let communityService: any CommunityBackend
    let checkInEngine: any CheckInSubmitting
    let liveSyncService: any CommunityLiveSyncing
    let rewardedAdCoordinator: RewardedAdCoordinator

    // MARK: - Init
    init(
        config: SupabaseConfig,
        sessionStore: SupabaseSessionStore,
        authClient: SupabaseAuthClient,
        postgrest: SupabasePostgREST,
        storage: SupabaseStorageClient,
        realtime: SupabaseRealtimeClient,
        communityService: any CommunityBackend,
        checkInEngine: any CheckInSubmitting,
        liveSyncService: any CommunityLiveSyncing,
        rewardedAdCoordinator: RewardedAdCoordinator
    ) {
        self.config = config
        self.sessionStore = sessionStore
        self.authClient = authClient
        self.postgrest = postgrest
        self.storage = storage
        self.realtime = realtime
        self.communityService = communityService
        self.checkInEngine = checkInEngine
        self.liveSyncService = liveSyncService
        self.rewardedAdCoordinator = rewardedAdCoordinator
    }

    // MARK: - Body / Public API
    /// Builds the graph. Returns `nil` when the bundle has no Supabase
    /// configuration — the caller then falls back to the in-memory doubles.
    static func make(bundle: Bundle = .main) -> BackendComposition? {
        guard let config = try? SupabaseConfig.load(from: bundle) else { return nil }
        return make(config: config)
    }

    static func make(
        config: SupabaseConfig,
        adPresenter: any RewardedAdPresenting = UnavailableRewardedAdPresenter()
    ) -> BackendComposition {
        let baseClient = URLSessionNetworkClient(baseURL: config.apiBaseURL, logger: nil)
        let authClient = SupabaseAuthClient(config: config, client: baseClient)
        let sessionStore = SupabaseSessionStore(
            keychain: KeychainStore(),
            refresher: { session in try await authClient.refresh(session: session) }
        )
        let interceptor = SupabaseAuthInterceptor(
            publishableKey: config.publishableKey,
            sessionProvider: sessionStore
        )
        let authenticatedClient = URLSessionNetworkClient(
            baseURL: config.apiBaseURL,
            interceptors: [.request(interceptor)],
            logger: nil
        )
        let retryingClient = AuthenticatedNetworkClient(
            baseURL: config.apiBaseURL,
            client: authenticatedClient,
            sessionProvider: sessionStore
        )
        let postgrest = SupabasePostgREST(
            baseURL: config.apiBaseURL,
            publishableKey: config.publishableKey,
            client: retryingClient
        )
        let storage = SupabaseStorageClient(
            baseURL: config.apiBaseURL,
            publishableKey: config.publishableKey,
            client: retryingClient
        )
        let realtime = SupabaseRealtimeClient.make(config: config) { [sessionStore] in
            try await sessionStore.accessToken()
        }
        let community = SupabaseCommunityService(
            postgrest: postgrest,
            sessionProvider: sessionStore,
            realtime: realtime
        )
        let checkIn = SupabaseCheckInService(
            postgrest: postgrest,
            groupsListing: community,
            storage: storage,
            sessionProvider: sessionStore
        )
        return BackendComposition(
            config: config,
            sessionStore: sessionStore,
            authClient: authClient,
            postgrest: postgrest,
            storage: storage,
            realtime: realtime,
            communityService: community,
            checkInEngine: checkIn,
            liveSyncService: RemoteCommunitySyncService(postgrest: postgrest),
            rewardedAdCoordinator: RewardedAdCoordinator(
                postgrest: postgrest,
                adPresenter: adPresenter
            )
        )
    }

    // MARK: - Subviews / Private Helpers
}
