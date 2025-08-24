import Foundation
import SwiftUpdater

/// A GitHub release.
public struct SUGitHubRelease: Sendable {
    /// The name.
    public let name: String

    /// The body.
    public let body: String

    /// The semantic version.
    public let version: SUVersion

    /// Whether this release is a prerelease.
    public let isPrerelease: Bool

    /// The download URL.
    public let downloadURL: URL
}
