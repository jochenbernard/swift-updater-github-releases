// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftUpdaterGitHubReleases",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "SwiftUpdaterGitHubReleases",
            targets: ["SwiftUpdaterGitHubReleases"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "SwiftUpdaterGitHubReleases",
            plugins: [
                .plugin(
                    name: "SwiftLintBuildToolPlugin",
                    package: "SwiftLintPlugins"
                )
            ]
        ),
        .testTarget(
            name: "SwiftUpdaterGitHubReleasesTests",
            dependencies: ["SwiftUpdaterGitHubReleases"],
            plugins: [
                .plugin(
                    name: "SwiftLintBuildToolPlugin",
                    package: "SwiftLintPlugins"
                )
            ]
        )
    ]
)
