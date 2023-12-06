//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import SwiftUI
import OpenAPIRuntime
import OpenAPIURLSession

/// A content view that can make HTTP requests to the GreetingService
/// running on localhost to fetch customized greetings.
///
/// By default, it makes live network calls, but it can be provided
/// with `MockClient` to make mocked in-memory calls only, which is more
/// appropriate in previews and tests.
struct ContentView: View {
    @State private var greeting: String = "Hello, Stranger!"
    @State private var name: String = "Stranger"
    let client: any APIProtocol
    init(client: any APIProtocol) { self.client = client }
    init() {
        if let stringValue = ProcessInfo.processInfo.environment["USE_MOCK_CLIENT"], let boolValue = Bool(stringValue),
            boolValue
        {
            // Allow using the mock client in UI tests.
            self.init(client: MockClient())
        } else {
            // By default, make live network calls.
            self.init(
                client: Client(serverURL: URL(string: "http://localhost:8080/api")!, transport: URLSessionTransport())
            )
        }
    }
    func updateGreeting() async {
        do {
            let response = try await client.getGreeting(query: .init(name: name))
            greeting = try response.ok.body.json.message
        } catch { greeting = "Error: \(error.localizedDescription)" }
    }
    var body: some View {
        VStack {
            Image(systemName: "globe").imageScale(.large)
            Text(greeting).accessibilityIdentifier("greeting-label")
            Divider()
            TextField("Name", text: $name)
            Button("Refresh greeting") { Task { await updateGreeting() } }
        }
        .padding().buttonStyle(.borderedProminent).font(.system(size: 20))
    }
}

// A mock client used in previews and tests to avoid making live network calls.
struct MockClient: APIProtocol {
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        let name = input.query.name ?? "Stranger"
        return .ok(.init(body: .json(.init(message: "(Mock) Hello, \(name)!"))))
    }
}

#Preview {
    // Use the mock client in previews instead of live network calls.
    ContentView(client: MockClient())
}
