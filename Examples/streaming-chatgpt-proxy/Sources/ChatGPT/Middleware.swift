//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import Foundation
import HTTPTypes
import OpenAPIRuntime

package struct HeaderFieldMiddleware: ClientMiddleware {
    var name: HTTPField.Name
    var value: String

    package static func authTokenFromEnvironment(_ environmentVariable: String) -> Self {
        guard let token = ProcessInfo.processInfo.environment[environmentVariable] else {
            fatalError("Please set \(environmentVariable) environment variable.")
        }
        return Self(name: .authorization, value: "Bearer \(token)")
    }

    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[name] = value
        return try await next(request, body, baseURL)
    }
}
