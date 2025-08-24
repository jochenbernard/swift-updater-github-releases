import Foundation

final class SUGitHubDownload: NSObject, URLSessionDownloadDelegate {
    private let url: URL
    private let urlSession: URLSession
    private let onProgress: @Sendable (CGFloat) -> Void
    @MainActor private var continuation: CheckedContinuation<URL, Swift.Error>?

    init(
        url: URL,
        urlSession: URLSession,
        onProgress: @Sendable @escaping (CGFloat) -> Void
    ) {
        self.url = url
        self.urlSession = urlSession
        self.onProgress = onProgress
    }

    @MainActor
    func start() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            guard self.continuation == nil else {
                continuation.resume(throwing: Error.downloadAlreadyStarted)
                return
            }

            self.continuation = continuation

            let urlRequest = URLRequest(url: url)
            let downloadTask = urlSession.downloadTask(with: urlRequest)
            downloadTask.delegate = self
            downloadTask.resume()
        }
    }

    func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask, // swiftlint:disable:this unused_parameter
        didWriteData bytesWritten: Int64, // swiftlint:disable:this unused_parameter
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        onProgress(progress)
    }

    func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask, // swiftlint:disable:this unused_parameter
        didFinishDownloadingTo location: URL
    ) {
        let destination = location
            .deletingLastPathComponent()
            .appending(component: UUID().uuidString)
            .appendingPathExtension("tmp")

        do {
            try FileManager.default.moveItem(
                at: location,
                to: destination
            )

            Task { @MainActor in
                continuation?.resume(returning: destination)
                continuation = nil
            }
        } catch {
            Task { @MainActor in
                continuation?.resume(throwing: error)
                continuation = nil
            }
        }
    }

    func urlSession(
        _: URLSession,
        task: URLSessionTask, // swiftlint:disable:this unused_parameter
        didCompleteWithError error: (any Swift.Error)?
    ) {
        Task { @MainActor in
            continuation?.resume(throwing: error ?? Error.downloadFailed)
            continuation = nil
        }
    }

    enum Error: Swift.Error {
        case downloadAlreadyStarted
        case downloadFailed
    }
}
