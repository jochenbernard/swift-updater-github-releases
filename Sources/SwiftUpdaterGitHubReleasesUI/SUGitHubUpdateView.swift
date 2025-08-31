import SwiftUI
import SwiftUpdaterGitHubReleases

public struct SUGitHubUpdateView: View {
    private let state: SUGitHubUpdate.State

    init(state: SUGitHubUpdate.State) {
        self.state = state
    }

    public init(_ update: SUGitHubUpdate) {
        self.init(state: update.state)
    }

    public var body: some View {
        ProgressView(
            value: progress,
            label: {
                Text("Installing update...")
            },
            currentValueLabel: {
                currentProgressLabel
            }
        )
        .tint(tint)
    }

    private var progress: CGFloat? {
        switch state {
        case .waiting, .extracting, .installing, .completed:
            nil

        case .downloading(let progress):
            progress

        case .canceled, .failed:
            1.0
        }
    }

    private var currentProgressLabel: some View {
        switch state {
        case .waiting, .downloading:
            Text("Downloading...")

        case .extracting:
            Text("Extracting...")

        case .installing:
            Text("Installing...")

        case .completed:
            Text("Completed")

        case .canceled:
            Text("Canceled")

        case .failed(let error):
            Text(String(describing: error))
        }
    }

    private var tint: HierarchicalShapeStyle? {
        switch state {
        case .waiting, .downloading, .extracting, .installing, .completed:
            nil

        case .canceled, .failed:
            .secondary
        }
    }
}

#Preview {
    SUGitHubUpdateView(state: .downloading(progress: 0.5))
        .padding()
}
