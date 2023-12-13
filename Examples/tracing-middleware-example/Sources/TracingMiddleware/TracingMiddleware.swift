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
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Tracing
import TracingOpenTelemetrySemanticConventions

package actor TracingMiddleware { package init() {} }

extension TracingMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        try await withSpan(operationID, ofKind: .client) { span in
            span.addEvent("Sending request")
            span.attributes.http.method = request.method.rawValue
            span.attributes.http.target = request.path
            let (response, responseBody) = try await next(request, body, baseURL)
            span.attributes.http.statusCode = response.status.code
            span.addEvent("Received response")
            return (response, responseBody)
        }
    }
}

extension TracingMiddleware: ServerMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        try await withSpan(operationID, ofKind: .server) { span in
            span.addEvent("Received request")
            span.attributes.http.method = request.method.rawValue
            span.attributes.http.target = request.path
            let (response, responseBody) = try await next(request, body, metadata)
            span.attributes.http.statusCode = response.status.code
            span.addEvent("Sending response")
            return (response, responseBody)
        }
    }
}
