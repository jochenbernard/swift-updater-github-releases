import Foundation
import SwiftUpdater

public struct SUGitHubRelease {
    public let name: String
    public let body: String
    public let version: SUVersion
    public let isPrerelease: Bool
    public let url: URL
}
