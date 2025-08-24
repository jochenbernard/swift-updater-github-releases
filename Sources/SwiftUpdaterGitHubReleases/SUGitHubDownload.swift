import Foundation

final class SUGitHubDownload: NSObject, URLSessionDownloadDelegate {
    private let url: URL
    private let urlSession: URLSession
    private let onProgress: (CGFloat) -> Void
    private var continuation: CheckedContinuation<URL, Swift.Error>?

    init(
        url: URL,
        urlSession: URLSession,
        onProgress: @escaping (CGFloat) -> Void
    ) {
        self.url = url
        self.urlSession = urlSession
        self.onProgress = onProgress
    }

    func start() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
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

            continuation?.resume(returning: destination)
        } catch {
            continuation?.resume(throwing: error)
        }

        continuation = nil
    }

    func urlSession(
        _: URLSession,
        task: URLSessionTask, // swiftlint:disable:this unused_parameter
        didCompleteWithError error: (any Swift.Error)?
    ) {
        continuation?.resume(throwing: error ?? Error.failed)
        continuation = nil
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

    enum Error: Swift.Error {
        case failed
    }
}
