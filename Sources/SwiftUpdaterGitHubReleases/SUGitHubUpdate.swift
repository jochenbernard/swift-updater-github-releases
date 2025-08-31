import Foundation
import SwiftUpdater

@Observable
@MainActor
public class SUGitHubUpdate {
    private let urlSession: URLSession
    private let extractor: SUUpdateExtractor
    private let updater: SUUpdater

    public let release: SUGitHubRelease

    public private(set) var state: State

    init(
        urlSession: URLSession,
        extractor: SUUpdateExtractor,
        updater: SUUpdater,
        release: SUGitHubRelease
    ) {
        self.urlSession = urlSession
        self.extractor = extractor
        self.updater = updater
        self.release = release
        self.state = .waiting
    }

    public func start() throws(Error) {
        if case .canceled = state {
            throw Error.updateWasCanceled
        }

        guard case .waiting = state else {
            throw Error.updateAlreadyStarted
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

                try updater.relaunch()
            } catch {
                state = .failed(error)
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

        state = .extracting

        let update = try await extractor.extract(from: download)
        defer { remove(update) }

        if case .canceled = state {
            return
        }

        state = .installing

        try updater.install(from: update)
    }

    private func download() async throws -> URL {
        let download = SUGitHubDownload(
            url: release.downloadURL,
            urlSession: urlSession,
            onProgress: { progress in
                Task { @MainActor in
                    guard case .downloading = self.state else {
                        return
                    }

                    self.state = .downloading(progress: progress)
                }
            }
        )

        return try await download.start()
    }

    private func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    public enum State {
        case waiting
        case downloading(progress: CGFloat)
        case extracting
        case installing
        case completed
        case canceled
        case failed(Swift.Error)
    }

    public enum Error: Swift.Error {
        case updateWasCanceled
        case updateAlreadyStarted
    }
}
