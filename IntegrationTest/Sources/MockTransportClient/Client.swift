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
import Types
import Client
import OpenAPIRuntime
import Foundation

struct MockClientTransport: ClientTransport {
    func send(_ request: Request, baseURL: URL, operationID: String) async throws -> Response { .init(statusCode: 200) }
}

func run() async throws {
    let client = Client(serverURL: try Servers.server1(), transport: MockClientTransport())
    _ = try await client.getGreeting(.init())
}
