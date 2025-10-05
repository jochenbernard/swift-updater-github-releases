import Foundation

struct GitHubRepoAPI {
    private let baseURL: URL
    private let urlSession: URLSession

    init?(
        owner: String,
        repository: String,
        urlSession: URLSession
    ) {
        guard
            let baseURL = URL(string: "https://api.github.com")?.appending(
                components: "repos",
                owner,
                repository
            )
        else {
            return nil
        }

        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    func fetchAllReleases() async throws -> [Release] {
        let url = baseURL.appending(component: "releases")
        let (data, _) = try await urlSession.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(
            [Release].self,
            from: data
        )
    }

    struct Release: Decodable {
        let tagName: String
        let name: String
        let draft: Bool
        let prerelease: Bool
        let assets: [Asset]
        let body: String
    }

    struct Asset: Decodable {
        let name: String
        let browserDownloadUrl: URL
    }
}
