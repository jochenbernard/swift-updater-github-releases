import Foundation
import SwiftUpdater

public final class SUGitHubReleasesUpdater: Sendable {
    private let api: GitHubRepoAPI
    private let assetName: String
    private let urlSession: URLSession

    public init?(
        owner: String,
        repo: String,
        assetName: String,
        urlSession: URLSession = .shared
    ) {
        guard
            let api = GitHubRepoAPI(
                owner: owner,
                repo: repo,
                urlSession: urlSession
            )
        else {
            return nil
        }

        self.api = api
        self.assetName = assetName
        self.urlSession = urlSession
    }

    public func getReleases() async throws -> [SUGitHubRelease] {
        try await api
            .getReleases()
            .compactMap { release in
                guard
                    !release.draft,
                    let version = SUVersion(string: release.tagName),
                    let url = release.assets.first(where: { $0.name == assetName })?.browserDownloadUrl
                else {
                    return nil
                }

                return SUGitHubRelease(
                    name: release.name,
                    body: release.body,
                    version: version,
                    isPrerelease: release.prerelease,
                    url: url
                )
            }
            .sorted(by: { $0.version > $1.version })
    }

    // swiftlint:disable:next discouraged_optional_boolean
    public func getLatestRelease(isPrerelease: Bool? = false) async throws -> SUGitHubRelease? {
        try await getReleases().first { release in
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
            release: release
        )
    }
}
