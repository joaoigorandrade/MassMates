import Foundation

/// The mapping of a backend failure onto the domain error the UI already
/// knows. It lives in its own file because it is a concern of its own.
extension CommunityGroupError {
    static func map(_ error: any Error) -> CommunityGroupError {
        if let domainError = error as? CommunityGroupError { return domainError }
        guard let backendError = error as? BackendError else {
            return .network(BackendError.transport(String(describing: error)).userMessage)
        }
        return map(backendError)
    }

    static func map(_ backendError: BackendError) -> CommunityGroupError {
        switch backendError {
        case .unauthorized, .sessionMissing:
            return .notAuthorized
        case .forbidden:
            return .notAuthorized
        case .notFound:
            return .groupNotFound
        case .rpc(_, let key):
            return mapRPCKey(key)
        case .http(_, _, let message):
            return .network(message ?? backendError.userMessage)
        default:
            return .network(backendError.userMessage)
        }
    }

    private static func mapRPCKey(_ key: String) -> CommunityGroupError {
        let normalized = key.lowercased()
        if normalized.contains("slot limit") || normalized.contains("slot_limit") {
            return .personalSlotLimitReached
        }
        if normalized.contains("last admin") || normalized.contains("last_admin") {
            return .lastAdminCannotLeave
        }
        if normalized.contains("invalid invite code") || normalized.contains("invite_code") {
            return .invalidInviteCode
        }
        if normalized.contains("not_a_group_member") || normalized.contains("not a group member") {
            return .notAuthorized
        }
        if normalized.contains("confession") {
            return .confessionSharingForbidden
        }
        return .network(BackendError.rpc(statusCode: 0, key: key).userMessage)
    }
}
