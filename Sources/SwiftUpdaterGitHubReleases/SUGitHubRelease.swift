import Foundation
import SwiftUpdater

/// A GitHub release.
public struct SUGitHubRelease: Sendable {
    /// The name of the release.
    public let name: String

    /// The body of the release.
    public let body: String

    /// The semantic version of the release.
    public let version: SUVersion

    /// Whether this release is a prerelease.
    public let isPrerelease: Bool

    /// The download URL of the release.
    public let downloadURL: URL
}
