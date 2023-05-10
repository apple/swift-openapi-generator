import OpenAPIRuntime
import OpenAPIURLSession

let client = Client(
    serverURL: try Servers.server2(),
    transport: URLSessionTransport()
)
