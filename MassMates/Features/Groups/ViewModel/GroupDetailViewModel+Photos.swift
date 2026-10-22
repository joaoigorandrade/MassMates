import Foundation

/// The witness photos of the visible feed posts. The signed URLs are resolved
/// in **one batched** request (the `signed-witness-url` Edge Function), never
/// one request per photo.
extension GroupDetailViewModel {
    // MARK: - Body / Public API
    func loadWitnessPhotoURLs() async {
        guard let storage else { return }
        let paths = visibleWitnessPhotoPaths()
        guard !paths.isEmpty else { return }
        let missing = paths.filter { signedPhotoURLsByPath[$0] == nil }
        guard !missing.isEmpty else { return }
        let urls = (try? await storage.signedWitnessURLs(paths: missing)) ?? [:]
        for (path, url) in urls {
            signedPhotoURLsByPath[path] = url
        }
    }

    func witnessPhotoURL(for post: GroupFeedPost) -> URL? {
        guard let path = post.witnessPhotoPath else { return nil }
        return signedPhotoURLsByPath[path]
    }

    // MARK: - Subviews / Private Helpers
    private func visibleWitnessPhotoPaths() -> [String] {
        var paths: [String] = []
        for item in feedItems {
            guard case .post(let post) = item, let path = post.witnessPhotoPath else { continue }
            paths.append(path)
        }
        return paths
    }
}
