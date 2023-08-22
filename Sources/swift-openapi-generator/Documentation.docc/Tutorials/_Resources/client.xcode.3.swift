import OpenAPIURLSession

/// A client for interacting with the Greeting service.
public struct GreetingClient {

    /// Initializes a new instance of the GreetingClient.
    public init() {}

    /// Retrieves a greeting message from the Greeting service.
    ///
    /// - Parameter name: An optional name parameter to personalize the greeting..
    /// - Returns: A `String` containing the greeting message.
    /// - Throws: An error if there's an issue during the API request or response processing.
    public func getGreeting(name: String?) async throws -> String {
        let client = Client(
            serverURL: try Servers.server2(),
            transport: URLSessionTransport()
        )
        let response = try await client.getGreeting(
            .init(
                query: .init(name: name)
            )
        )
    }
}
