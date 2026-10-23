import Foundation

extension SupabaseCommunityService {
    // MARK: - Body / Public API
    func displayNames(for userIds: [String]) async -> [String: String] {
        let missing = userIds.filter { nameCache[$0] == nil }
        guard !missing.isEmpty else {
            return Dictionary(uniqueKeysWithValues: userIds.compactMap { id in
                nameCache[id].map { (id, $0) }
            })
        }
        let rows = (try? await postgrest.select(
            from: "profiles",
            columns: "id,display_name",
            filter: .contains(column: "id", values: missing)
        )) ?? []
        for (id, name) in SupabaseCommunityMapping.displayNameMap(from: rows) {
            nameCache[id] = name
        }
        return Dictionary(uniqueKeysWithValues: userIds.compactMap { id in
            nameCache[id].map { (id, $0) }
        })
    }

    func durationLabel(for item: JSONValue) -> String {
        let start = item["starts_on"]?.stringValue
        let end = item["ends_on"]?.stringValue
        guard let start, let end else { return "Jornada" }
        return "\(start) → \(end)"
    }
}
