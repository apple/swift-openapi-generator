import OpenAPIRuntime
import OpenAPIURLSession

let client = Client(
    serverURL: try Servers.Server2.url(),
    transport: URLSessionTransport()
)

let response = try await client.getGreeting(query: .init(name: "CLI"))
switch response {
case .ok(let okResponse):
    switch okResponse.body {
    case .json(let greeting):
        print(greeting.message)
    }
case .undocumented(statusCode: let statusCode, _):
    print("🥺 undocumented response: \(statusCode)")
}
