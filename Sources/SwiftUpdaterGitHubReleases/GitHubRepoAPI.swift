import Foundation

struct GitHubRepoAPI {
    private let baseURL: URL
    private let urlSession: URLSession

    init?(
        owner: String,
        repo: String,
        urlSession: URLSession
    ) {
        guard
            let baseURL = URL(string: "https://api.github.com")?.appending(
                components: "repos",
                owner,
                repo
            )
        else {
            return nil
        }

        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    func getReleases() async throws -> [Release] {
        let url = baseURL.appending(component: "releases")
        let data = try await urlSession.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(
            [Release].self,
            from: data.0
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
