import Foundation

/// The one object the composition root injects into the environment. It is the
/// union of every community protocol, so a single service satisfies them all.
@MainActor
protocol CommunityBackend: CommunityGroupsListing, CommunityGroupMutating, GroupFeedManaging,
    GroupChatManaging, GroupModerationManaging, GroupScoringManaging, GuardianAngelManaging,
    PrayerWallManaging, RewardManaging {}

/// The in-memory double satisfies the same composite, so the environment can
/// hold either implementation behind one type.
extension LocalCommunityGroupsService: CommunityBackend {}

/// The realtime seam: the row changes the app listens to while a group is
/// open. The channel is filtered by RLS server-side.
@MainActor
protocol CommunityRealtimeStreaming: AnyObject {
    func changes(for table: RealtimeTable) -> AsyncThrowingStream<RealtimeChange, Error>
    func startListening() async
    func stopListening() async
}

/// The tables the Supabase Realtime publication exposes.
enum RealtimeTable: String, Sendable, Equatable, CaseIterable {
    case chatMessages = "chat_messages"
    case amenReactions = "amen_reactions"
    case intentionPrayers = "intention_prayers"
}
