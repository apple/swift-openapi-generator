import OpenAPIRuntime
import OpenAPIURLSession

let client = Client(serverURL: try Servers.server2(), transport: URLSessionTransport())

let response = try await client.getGreeting(.init(query: .init(name: "CLI")))
print(response)
