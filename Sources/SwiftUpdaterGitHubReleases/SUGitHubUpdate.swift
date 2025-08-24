import Foundation
import SwiftUpdater

@Observable
@MainActor
public class SUGitHubUpdate {
    private let urlSession: URLSession
    public let release: SUGitHubRelease
    public private(set) var state: State

    init(
        urlSession: URLSession,
        release: SUGitHubRelease
    ) {
        self.urlSession = urlSession
        self.release = release
        self.state = .suspended
    }

    public func resume() {
        guard case .suspended = state else {
            return
        }

        state = .downloading(progress: .zero)

        Task {
            do {
                if case .canceled = state {
                    return
                }

                try await install()

                if case .canceled = state {
                    return
                }

                state = .completed

                SUUpdater.relaunch()
            } catch let error as Error {
                state = .failed(error)
            } catch {
                state = .failed(.unknown(error))
            }
        }
    }

    public func cancel() {
        state = .canceled
    }

    private func install() async throws {
        let download = try await download()
        defer { remove(download) }

        if case .canceled = state {
            return
        }

        state = .unzipping

        let directory = try unzip(download)
        defer { remove(directory) }

        if case .canceled = state {
            return
        }

        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        let apps = files.filter { file in
            file.pathExtension == "app"
        }

        guard apps.count == 1 else {
            throw Error.failedToUnzip
        }

        if case .canceled = state {
            return
        }

        state = .installing

        try SUUpdater.installUpdate(from: apps[apps.startIndex])
    }

    private func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func download() async throws -> URL {
        let download = SUGitHubDownload(
            url: release.url,
            urlSession: urlSession,
            onProgress: { progress in
                Task { @MainActor in
                    if case .canceled = self.state {
                        return
                    }

                    self.state = .downloading(progress: progress)
                }
            }
        )

        return try await download.start()
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

    public enum State {
        case suspended
        case downloading(progress: CGFloat)
        case unzipping
        case installing
        case completed
        case canceled
        case failed(Error)
    }

    public enum Error: Swift.Error {
        case failedToUnzip
        case unknown(Swift.Error)
    }
}
