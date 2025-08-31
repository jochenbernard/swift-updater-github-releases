import Foundation
import SwiftUpdater

public final class SUGitHubReleasesUpdater: Sendable {
    private let api: GitHubRepoAPI
    private let assetMatcher: SUFileMatcher
    private let extractor: SUUpdateExtractor
    private let urlSession: URLSession
    private let updater: SUUpdater

    public init?(
        owner: String,
        repository: String,
        assetMatcher: SUFileMatcher,
        extractor: SUUpdateExtractor,
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
        self.extractor = extractor
        self.urlSession = urlSession
        self.updater = SUUpdater(bundle: bundle)
    }

    public func getAllReleases() async throws -> [SUGitHubRelease] {
        try await api
            .getReleases()
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

    public func getLatestRelease(
        isPrerelease: Bool? = false // swiftlint:disable:this discouraged_optional_boolean
    ) async throws -> SUGitHubRelease? {
        try await getAllReleases().first { release in
            if let isPrerelease {
                release.isPrerelease == isPrerelease
            } else {
                true
            }
        }
    }

    @MainActor
    public func update(to release: SUGitHubRelease) -> SUGitHubUpdate {
        SUGitHubUpdate(
            urlSession: urlSession,
            extractor: extractor,
            updater: updater,
            release: release
        )
    }
}
