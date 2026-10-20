import Foundation
import Observation

enum CreateJoinGroupTab: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable, Codable {
    case joinByCode
    case createNew

    var id: String { rawValue }

    var title: String {
        switch self {
        case .joinByCode: "Entrar com Código"
        case .createNew: "Criar Grupo"
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
    private(set) var previewedGroup: CommunityGroup?
    private(set) var slotCapacity: GroupSlotCapacity
    private(set) var errorMessage: String?

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
        self.slotCapacity = listingService.slotCapacity()
        self.onGroupActivated = onGroupActivated
        if !prefilledInviteCode.isEmpty {
            previewInviteCode()
        }
    }

    // MARK: - Body / Public API
    func previewInviteCode() {
        errorMessage = nil
        do {
            previewedGroup = try listingService.previewGroup(forInviteInput: inviteInput)
        } catch {
            previewedGroup = nil
            errorMessage = error.userMessage
        }
    }

    @discardableResult
    func confirmJoinGroup() -> CommunityGroup? {
        errorMessage = nil
        do {
            let group = try mutatingService.joinGroup(byInviteInput: inviteInput)
            slotCapacity = listingService.slotCapacity()
            onGroupActivated(group)
            return group
        } catch {
            slotCapacity = listingService.slotCapacity()
            errorMessage = error.userMessage
            return nil
        }
    }

    @discardableResult
    func submitCreateGroup() -> CommunityGroup? {
        errorMessage = nil
        do {
            let created = try mutatingService.createGroup(draft)
            slotCapacity = listingService.slotCapacity()
            onGroupActivated(created)
            return created
        } catch {
            slotCapacity = listingService.slotCapacity()
            errorMessage = error.userMessage
            return nil
        }
    }

    func unlockRewardedSlot() {
        slotCapacity = mutatingService.unlockRewardedGroupSlot()
        errorMessage = nil
    }

    // MARK: - Subviews / Private Helpers
}
