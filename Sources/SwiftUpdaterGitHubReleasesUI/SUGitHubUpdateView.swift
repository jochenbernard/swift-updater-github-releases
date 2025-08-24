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
            value: nil as CGFloat?,
            label: {
                Text("Installing update...")
            },
            currentValueLabel: {
                currentValueLabel
            }
        )
        .tint(tint)
    }

    private var currentValueLabel: some View {
        switch state {
        case .suspended, .downloading:
            Text("Downloading...")

        case .unzipping:
            Text("Unzipping...")

        case .installing:
            Text("Installing...")

        case .completed:
            Text("Completed")

        case .canceled:
            Text("Canceled")

        case .failed(let error):
            Text(error.localizedDescription)
        }
    }

    private var tint: HierarchicalShapeStyle? {
        switch state {
        case .suspended, .downloading, .unzipping, .installing, .completed:
            nil

        case .canceled, .failed:
            .secondary
        }
    }
}

#Preview {
    SUGitHubUpdateView(state: .downloading)
        .padding()
}
