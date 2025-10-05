// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftUpdaterGitHubReleases",
    platforms: [.macOS(.v14)],
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
        ),
        .package(
            url: "https://github.com/jochenbernard/swift-updater",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "SwiftUpdaterGitHubReleases",
            dependencies: [
                .product(
                    name: "SwiftUpdater",
                    package: "swift-updater"
                )
            ],
            plugins: [
                .plugin(
                    name: "SwiftLintBuildToolPlugin",
                    package: "SwiftLintPlugins"
                )
            ]
        )
    ]
)
