import OpenAPIRuntime
import OpenAPIURLSession

let client = Client(
    serverURL: try Servers.Server2.url(),
    transport: URLSessionTransport()
)

let response = try await client.getGreeting(query: .init(name: "CLI"))
print(try response.ok.body.json.message)
