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
import OpenAPIRuntime
import OpenAPIURLSession
import Foundation

/// A hand-written Swift API for the greeting service, one that doesn't leak any generated code.
public struct GreetingClient {

    /// The underlying generated client to make HTTP requests to GreetingService.
    private let underlyingClient: any APIProtocol

    /// An internal initializer used by other initializers and by tests.
    /// - Parameter underlyingClient: The client to use to make HTTP requests.
    internal init(underlyingClient: any APIProtocol) { self.underlyingClient = underlyingClient }

    /// Creates a new client for GreetingService.
    public init() {
        self.init(
            underlyingClient: Client(
                serverURL: URL(string: "https://localhost:8080/api")!,
                transport: URLSessionTransport()
            )
        )
    }

    /// Fetches the customized greeting for the provided name.
    /// - Parameter name: The name for which to provide a greeting, or nil to get a default.
    /// - Returns: A customized greeting message.
    /// - Throws: An error if the underlying HTTP client fails.
    public func getGreeting(name: String?) async throws -> String {
        let response = try await underlyingClient.getGreeting(query: .init(name: name))
        return try response.ok.body.json.message
    }
}
