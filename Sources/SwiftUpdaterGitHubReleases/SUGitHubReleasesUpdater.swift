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
        self.urlSession = urlSession
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

    public func installRelease(_ release: SUGitHubRelease) {
        Task {
            do {
                try await installRelease(release)
            } catch {
                assertionFailure(String(describing: error))
            }
        }
    }

    private func installRelease(_ release: SUGitHubRelease) async throws {
        let download = try await downloadRelease(release)
        let directory = try unzip(download)

        try? FileManager.default.removeItem(at: download)

        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        let apps = files.filter { file in
            file.pathExtension == "app"
        }

        guard apps.count == 1 else {
            try? FileManager.default.removeItem(at: directory)
            throw Error.failedToUnzip
        }

        try SUUpdater.installUpdate(from: apps[apps.startIndex])

        try? FileManager.default.removeItem(at: directory)

        await SUUpdater.relaunch()
    }

    private func downloadRelease(_ release: SUGitHubRelease) async throws -> URL {
        let (url, _) = try await urlSession.download(from: release.url)
        return url
    }

    private func unzip(_ url: URL) throws -> URL {
        let destinationURL = url.deletingPathExtension()

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/unzip")
        process.arguments = [
            url.path(percentEncoded: false),
            "-d",
            destinationURL.path(percentEncoded: false)
        ]

        try process.run()

        process.waitUntilExit()

        guard process.terminationStatus == .zero else {
            throw Error.failedToUnzip
        }

        return destinationURL
    }

    enum Error: Swift.Error {
        case failedToUnzip
    }
}
