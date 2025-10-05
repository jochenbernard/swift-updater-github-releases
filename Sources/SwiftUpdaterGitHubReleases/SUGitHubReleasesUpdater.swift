import Foundation
import SwiftUpdater

/// An object that manages updates from GitHub releases.
public final class SUGitHubReleasesUpdater: Sendable {
    private let api: GitHubRepoAPI
    private let assetMatcher: SUFileMatcher
    private let updater: SUUpdater

    /// Creates a GitHub releases updater.
    ///
    /// - Parameters:
    ///   - owner: The owner of the repository.
    ///   - repository: The name of the repository.
    ///   - assetMatcher: The asset matcher to determine which asset of the release contains the update.
    ///   - downloader: The downloader to download updates. The default is `standard(urlSession:)`.
    ///   - extractor: The extractor to extract updates.
    ///   - urlSession: The URL session to send GitHub API requests. The default is `shared`.
    ///   - bundle: The bundle to update. The default is `main`.
    public init?(
        owner: String,
        repository: String,
        assetMatcher: SUFileMatcher,
        downloader: SUUpdateDownloader = .standard(),
        extractor: SUUpdateExtractor?,
        urlSession: URLSession = .shared,
        bundle: Bundle = .main
    ) {
        guard
            let api = GitHubRepoAPI(
                owner: owner,
                repository: repository,
                urlSession: urlSession
            )
        else {
            return nil
        }

        self.api = api
        self.assetMatcher = assetMatcher
        self.updater = SUUpdater(
            bundle: bundle,
            downloader: downloader,
            extractor: extractor
        )
    }

    /// Fetches all releases, sorted from highest version to lowest.
    public func fetchAllReleases() async throws -> [SUGitHubRelease] {
        try await api
            .fetchAllReleases()
            .compactMap { release in
                guard
                    !release.draft,
                    let version = SUVersion(string: release.tagName)
                else {
                    return nil
                }

                let assets = release.assets.filter { asset in
                    assetMatcher.matches(asset.name)
                }

                guard
                    assets.count <= 1,
                    let downloadURL = assets.first?.browserDownloadUrl
                else {
                    return nil
                }

                return SUGitHubRelease(
                    name: release.name,
                    body: release.body,
                    version: version,
                    isPrerelease: release.prerelease,
                    downloadURL: downloadURL
                )
            }
            .sorted(by: { $0.version > $1.version })
    }

    /// Fetches the latest release that optionally satisfies the prerelease requirement.
    ///
    /// - Parameter isPrerelease: Whether the release should be a prerelease. When `true`, the latest prerelease is
    ///                           returned. When `false`, the latest non-prerelease is returned. When `nil`, the latest
    ///                           release is returned regardless of it being a prerelease. The default is `false`.
    public func fetchLatestRelease(
        isPrerelease: Bool? = false // swiftlint:disable:this discouraged_optional_boolean
    ) async throws -> SUGitHubRelease? {
        try await fetchAllReleases().first { release in
            if let isPrerelease {
                release.isPrerelease == isPrerelease
            } else {
                true
            }
        }
    }

    /// Creates an update for the specified release.
    ///
    /// - Parameter release: The release.
    ///
    /// This update still has to be started using the `start()` method.
    @MainActor
    public func update(to release: SUGitHubRelease) -> SUUpdate {
        updater.update(from: release.downloadURL)
    }
}
