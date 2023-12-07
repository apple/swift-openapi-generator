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
import Metrics
import OpenAPIRuntime

package struct MetricsMiddleware {
    package var counterPrefix: String

    package init(counterPrefix: String) { self.counterPrefix = counterPrefix }
}

extension MetricsMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        do {
            let (response, responseBody) = try await next(request, body, baseURL)
            Counter(label: "\(counterPrefix).\(operationID).\(response.status.code.description)").increment()
            return (response, responseBody)
        } catch {
            Counter(label: "\(counterPrefix).\(operationID).error").increment()
            throw error
        }
    }
}

extension MetricsMiddleware: ServerMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        func recordResult(_ result: String) { Counter(label: "\(counterPrefix).\(operationID).\(result)").increment() }
        do {
            let (response, responseBody) = try await next(request, body, metadata)
            Counter(label: "\(counterPrefix).\(operationID).\(response.status.code.description)").increment()
            return (response, responseBody)
        } catch {
            Counter(label: "\(counterPrefix).\(operationID).error").increment()
            throw error
        }
    }
}
