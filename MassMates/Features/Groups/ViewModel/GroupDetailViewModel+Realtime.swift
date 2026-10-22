import Foundation

/// The live part of the group detail: the Realtime subscriptions and the live
/// pulse of the collective goal.
extension GroupDetailViewModel {
    // MARK: - Body / Public API
    /// Subscribes to the live channels of the open group. The `.task {}`
    /// modifier of the view cancels this method when the view disappears, which
    /// tears the subscriptions down.
    func startRealtime() async {
        guard let realtimeService else { return }
        await realtimeService.startListening()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.consumeChatChanges() }
            group.addTask { await self.consumeCounterChanges() }
        }
        await realtimeService.stopListening()
    }

    // MARK: - Subviews / Private Helpers
    func refreshLivePulse() async {
        guard let liveSyncService else { return }
        guard let pulse = try? await liveSyncService.fetchLiveGroupPulse(groupId: group.id) else { return }
        livePulse = pulse
    }

    func consumeChatChanges() async {
        guard let realtimeService else { return }
        do {
            for try await change in realtimeService.changes(for: .chatMessages) {
                guard change.eventType == .insert else { continue }
                chatMessages = (try? await chatService.chatMessages(for: group.id)) ?? chatMessages
            }
        } catch {
            return
        }
    }

    func consumeCounterChanges() async {
        guard let realtimeService else { return }
        let reactions = realtimeService.changes(for: .amenReactions)
        let prayers = realtimeService.changes(for: .intentionPrayers)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.consumeReactions(reactions) }
            group.addTask { await self.consumePrayers(prayers) }
        }
    }

    func consumeReactions(_ stream: AsyncThrowingStream<RealtimeChange, Error>) async {
        do {
            for try await change in stream {
                guard change.eventType == .insert else { continue }
                await refreshFeed()
            }
        } catch {
            return
        }
    }

    func consumePrayers(_ stream: AsyncThrowingStream<RealtimeChange, Error>) async {
        do {
            for try await change in stream {
                guard change.eventType == .insert else { continue }
                prayerIntentions = (try? await prayerWallService.prayerIntentions(for: group.id)) ?? prayerIntentions
            }
        } catch {
            return
        }
    }
}
