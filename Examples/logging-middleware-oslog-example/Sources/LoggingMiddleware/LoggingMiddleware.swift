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
#if canImport(Darwin)
import OpenAPIRuntime
import Foundation
import HTTPTypes
import OSLog

package actor LoggingMiddleware {
    private let logger: Logger
    package let bodyLoggingPolicy: BodyLoggingPolicy

    package init(logger: Logger = defaultLogger, bodyLoggingConfiguration: BodyLoggingPolicy = .never) {
        self.logger = logger
        self.bodyLoggingPolicy = bodyLoggingConfiguration
    }

    fileprivate static var defaultLogger: Logger {
        Logger(subsystem: "com.apple.swift-openapi", category: "logging-middleware")
    }
}

extension LoggingMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let (requestBodyToLog, requestBodyForNext) = try await bodyLoggingPolicy.process(body)
        log(request, requestBodyToLog)
        do {
            let (response, responseBody) = try await next(request, requestBodyForNext, baseURL)
            let (responseBodyToLog, responseBodyForNext) = try await bodyLoggingPolicy.process(responseBody)
            log(request, response, responseBodyToLog)
            return (response, responseBodyForNext)
        } catch {
            log(request, failedWith: error)
            throw error
        }
    }
}

extension LoggingMiddleware: ServerMiddleware {
    package func intercept(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        metadata: OpenAPIRuntime.ServerRequestMetadata,
        operationID: String,
        next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata)
            async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        let (requestBodyToLog, requestBodyForNext) = try await bodyLoggingPolicy.process(body)
        log(request, requestBodyToLog)
        do {
            let (response, responseBody) = try await next(request, requestBodyForNext, metadata)
            let (responseBodyToLog, responseBodyForNext) = try await bodyLoggingPolicy.process(responseBody)
            log(request, response, responseBodyToLog)
            return (response, responseBodyForNext)
        } catch {
            log(request, failedWith: error)
            throw error
        }
    }
}

extension LoggingMiddleware {
    func log(_ request: HTTPRequest, _ requestBody: BodyLoggingPolicy.BodyLog) {
        logger.debug(
            "Request: \(request.method, privacy: .public) \(request.path ?? "<nil>", privacy: .public) body: \(requestBody, privacy: .auto)"
        )
    }

    func log(_ request: HTTPRequest, _ response: HTTPResponse, _ responseBody: BodyLoggingPolicy.BodyLog) {
        logger.debug(
            "Response: \(request.method, privacy: .public) \(request.path ?? "<nil>", privacy: .public) \(response.status, privacy: .public) body: \(responseBody, privacy: .auto)"
        )
    }

    func log(_ request: HTTPRequest, failedWith error: any Error) {
        logger.warning("Request failed. Error: \(error.localizedDescription)")
    }
}

package enum BodyLoggingPolicy {
    /// Never log request or response bodies.
    case never
    /// Log request and response bodies that have a known length less than or equal to `maxBytes`.
    case upTo(maxBytes: Int)

    enum BodyLog: Equatable, CustomStringConvertible {
        /// There is no body to log.
        case none
        /// The policy forbids logging the body.
        case redacted
        /// The body was of unknown length.
        case unknownLength
        /// The body exceeds the maximum size for logging allowed by the policy.
        case tooManyBytesToLog(Int64)
        /// The body can be logged.
        case complete(Data)

        var description: String {
            switch self {
            case .none: return "<none>"
            case .redacted: return "<redacted>"
            case .unknownLength: return "<unknown length>"
            case .tooManyBytesToLog(let byteCount): return "<\(byteCount) bytes>"
            case .complete(let data):
                if let string = String(data: data, encoding: .utf8) { return string }
                return String(describing: data)
            }
        }
    }

    func process(_ body: HTTPBody?) async throws -> (bodyToLog: BodyLog, bodyForNext: HTTPBody?) {
        switch (body?.length, self) {
        case (.none, _): return (.none, body)
        case (_, .never): return (.redacted, body)
        case (.unknown, _): return (.unknownLength, body)
        case (.known(let length), .upTo(let maxBytesToLog)) where length > maxBytesToLog:
            return (.tooManyBytesToLog(length), body)
        case (.known, .upTo(let maxBytesToLog)):
            let bodyData = try await Data(collecting: body!, upTo: maxBytesToLog)
            return (.complete(bodyData), HTTPBody(bodyData))
        }
    }
}
#endif  // canImport(Darwin)
