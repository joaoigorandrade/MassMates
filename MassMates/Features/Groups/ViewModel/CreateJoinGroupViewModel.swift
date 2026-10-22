import Foundation
import Observation

enum CreateJoinGroupTab: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case joinByCode
    case createNew

    var id: String { rawValue }

    var title: String {
        switch self {
        case .joinByCode: "Entrar com Código"
        case .createNew: "Criar Fraternidade"
        }
    }
}

@MainActor
@Observable
final class CreateJoinGroupViewModel {
    // MARK: - Dependencies & State
    private let listingService: any CommunityGroupsListing
    private let mutatingService: any CommunityGroupMutating
    private let onGroupActivated: @MainActor (CommunityGroup) -> Void
    var selectedTab: CreateJoinGroupTab
    var inviteInput: String
    var draft: GroupCreationDraft = GroupCreationDraft()
    var selectedPatronSaint: String = "Sta. Teresinha"
    var isSecretGuardianAngelEnabled: Bool = true
    var isPhotoCheckInEnabled: Bool = false
    var pilgrimLimit: Double = 12
    private(set) var previewedGroup: CommunityGroup?
    private(set) var slotCapacity: GroupSlotCapacity
    private(set) var errorMessage: String?

    var inviteCodeInput: String {
        get { inviteInput }
        set { inviteInput = newValue }
    }

    // MARK: - Init
    init(
        initialTab: CreateJoinGroupTab = .joinByCode,
        prefilledInviteCode: String = "",
        listingService: any CommunityGroupsListing = LocalCommunityGroupsService(),
        mutatingService: (any CommunityGroupMutating)? = nil,
        onGroupActivated: @escaping @MainActor (CommunityGroup) -> Void = { _ in }
    ) {
        self.selectedTab = initialTab
        self.inviteInput = prefilledInviteCode
        self.listingService = listingService
        if let mutatingService {
            self.mutatingService = mutatingService
        } else if let combined = listingService as? (any CommunityGroupMutating) {
            self.mutatingService = combined
        } else {
            self.mutatingService = LocalCommunityGroupsService()
        }
        self.slotCapacity = LocalCommunityGroupsService.sampleSlotCapacity()
        self.onGroupActivated = onGroupActivated
    }

    // MARK: - Body / Public API
    func load() async {
        await refreshSlotCapacity()
        if !inviteInput.isEmpty {
            await previewInviteCode()
        }
    }

    func previewInviteCode() async {
        errorMessage = nil
        do {
            previewedGroup = try await listingService.previewGroup(forInviteInput: inviteInput)
        } catch {
            previewedGroup = nil
            errorMessage = error.userMessage
        }
    }

    @discardableResult
    func confirmJoinGroup() async -> CommunityGroup? {
        errorMessage = nil
        do {
            let group = try await mutatingService.joinGroup(byInviteInput: inviteInput)
            await refreshSlotCapacity()
            onGroupActivated(group)
            return group
        } catch {
            await refreshSlotCapacity()
            errorMessage = error.userMessage
            return nil
        }
    }

    @discardableResult
    func submitCreateGroup() async -> CommunityGroup? {
        errorMessage = nil
        if let windowError = draft.challengeWindowErrorMessage {
            errorMessage = windowError
            return nil
        }
        do {
            let created = try await mutatingService.createGroup(draft)
            await refreshSlotCapacity()
            onGroupActivated(created)
            return created
        } catch {
            await refreshSlotCapacity()
            errorMessage = error.userMessage
            return nil
        }
    }

    /// Switches the group type. A **dated challenge** gets the default
    /// window (today → today + 40 days); a fraternity carries no dates.
    func selectType(_ type: CommunityGroupType) {
        draft.type = type
        draft.normalizeWindowForType()
        errorMessage = nil
    }

    func unlockRewardedSlot() async {
        slotCapacity = (try? await mutatingService.unlockRewardedGroupSlot()) ?? slotCapacity
        errorMessage = nil
    }

    // MARK: - Subviews / Private Helpers
    private func refreshSlotCapacity() async {
        slotCapacity = (try? await listingService.slotCapacity()) ?? slotCapacity
    }
}
