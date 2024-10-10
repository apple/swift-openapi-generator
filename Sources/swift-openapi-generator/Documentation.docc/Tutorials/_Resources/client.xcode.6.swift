import OpenAPIURLSession

public struct GreetingClient {

    public init() {}

    public func getGreeting(name: String?) async throws -> String {
        let client = Client(
            serverURL: try Servers.Server2.url(),
            transport: URLSessionTransport()
        )
        let response = try await client.getGreeting(query: .init(name: name))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let greeting):
                return greeting.message
            }
        case .undocumented(statusCode: let statusCode, _):
            return "🙉 \(statusCode)"
        }
    }
}
