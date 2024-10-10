import OpenAPIURLSession

public struct GreetingClient {

    public init() {}

    public func getGreeting(name: String?) async throws -> String {
        let client = Client(
            serverURL: try Servers.Server2.url(),
            transport: URLSessionTransport()
        )
        let response = try await client.getGreeting(query: .init(name: name))
    }
}
