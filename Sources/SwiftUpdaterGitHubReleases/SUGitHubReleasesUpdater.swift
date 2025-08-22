import Foundation
import SwiftUpdater

public final class SUGitHubReleasesUpdater: Sendable {
    private let api: GitHubRepoAPI
    private let assetName: String

    public init?(
        owner: String,
        repo: String,
        assetName: String,
        urlSession: URLSession
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
    }

    public func getLatestRelease() async throws -> SUGitHubRelease? {
        let releases = try await api.getReleases()

        for release in releases {
            guard
                !release.draft,
                let version = SUVersion(string: release.tagName),
                let url = release.assets.first(where: { $0.name == assetName })?.browserDownloadUrl
            else {
                continue
            }

            return SUGitHubRelease(
                name: release.name,
                body: release.body,
                version: version,
                isPrerelease: release.prerelease,
                url: url
            )
        }

        return nil
    }
}
