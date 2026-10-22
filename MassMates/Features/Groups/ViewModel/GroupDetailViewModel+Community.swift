import Foundation

/// The Guardian Angel, the Prayer Wall and the group chat of the detail.
extension GroupDetailViewModel {
    // MARK: - Body / Public API
    func optInGuardianAngel() async {
        guardianAngelState = (try? await guardianAngelService.optInToGuardianAngel(in: group.id, revealCycle: false))
            ?? guardianAngelState
    }

    func sendGuardianAngelPrayerNudge() async {
        guardianAngelState = (try? await guardianAngelService.sendGuardianAngelPrayerNudge(in: group.id))
            ?? guardianAngelState
    }

    func revealGuardianAngelCycle() async {
        guardianAngelState = (try? await guardianAngelService.optInToGuardianAngel(in: group.id, revealCycle: true))
            ?? guardianAngelState
    }

    func togglePrayedForIntention(_ intentionId: String) async {
        prayerIntentions = (try? await prayerWallService.togglePrayedForIntention(intentionId, in: group.id))
            ?? prayerIntentions
    }

    func submitPrayerIntention() async {
        errorMessage = nil
        do {
            prayerIntentions = try await prayerWallService.createPrayerIntention(
                in: group.id,
                text: newPrayerIntentionDraft
            )
            newPrayerIntentionDraft = ""
        } catch {
            errorMessage = error.userMessage
        }
    }

    func sendChatMessage() async {
        errorMessage = nil
        do {
            chatMessages = try await chatService.sendChatMessage(in: group.id, text: chatMessageDraft)
            chatMessageDraft = ""
        } catch {
            errorMessage = error.userMessage
        }
    }

    func savePinnedNotice() async {
        errorMessage = nil
        do {
            pinnedNotice = try await chatService.updatePinnedNotice(in: group.id, noticeText: pinnedNoticeDraft)
            isEditingPinnedNotice = false
        } catch {
            errorMessage = error.userMessage
        }
    }

}
