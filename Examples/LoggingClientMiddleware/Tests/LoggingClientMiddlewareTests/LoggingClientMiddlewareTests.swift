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
import XCTest

@testable import LoggingClientMiddleware

final class LoggingMiddlewareTests: XCTestCase {

    func testProcessBodyForLogging() async throws {
        for (body, config, expectedMessage): (HTTPBody?, LoggingMiddleware.BodyLoggingPolicy, LoggingMiddleware.BodyLog) in [
            (.none, .never, .none),
            (.none, .upTo(maxBytes: 5), .none),
            (HTTPBody("Hello", length: .unknown), .never, .redacted),
            (HTTPBody("Hello", length: .unknown), .upTo(maxBytes: 3), .unknownLength),
            (HTTPBody("Hello", length: .unknown), .upTo(maxBytes: 5), .unknownLength),
            (HTTPBody("Hello"), .never, .redacted),
            (HTTPBody("Hello"), .upTo(maxBytes: 3), .tooManyBytesToLog(5)),
            (HTTPBody("Hello"), .upTo(maxBytes: 5), .complete(Data("Hello".utf8))),
        ] {
            let (bodyToLog, _) = try await LoggingMiddleware(bodyLoggingConfiguration: config).processBodyForLogging(body)
            XCTAssertEqual(bodyToLog, expectedMessage)
        }
    }
}
