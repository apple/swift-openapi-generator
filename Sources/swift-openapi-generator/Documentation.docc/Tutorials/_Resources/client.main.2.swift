import OpenAPIRuntime
import OpenAPIURLSession

let client = Client(
    serverURL: try Servers.Server2.url(),
    transport: URLSessionTransport()
)
