import OpenAPIURLSession

public struct GreetingClient {

    public init() {}

    public func getGreeting(name: String?) async throws -> String {
        let client = Client(
            serverURL: try Servers.server2(),
            transport: URLSessionTransport()
        )
        let response = try await client.getGreeting(query: .init(name: name))
    }
}
