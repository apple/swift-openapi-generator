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
import XCTest

@testable import LoggingMiddleware

final class LoggingMiddlewareTests: XCTestCase {

    func testBodyLoggingPolicy() async throws {
        for (body, bodyLoggingPolicy, expectedMessage): (HTTPBody?, BodyLoggingPolicy, BodyLoggingPolicy.BodyLog) in [
            (.none, .never, .none), (.none, .upTo(maxBytes: 5), .none),
            (HTTPBody("Hello", length: .unknown), .never, .redacted),
            (HTTPBody("Hello", length: .unknown), .upTo(maxBytes: 3), .unknownLength),
            (HTTPBody("Hello", length: .unknown), .upTo(maxBytes: 5), .unknownLength),
            (HTTPBody("Hello"), .never, .redacted), (HTTPBody("Hello"), .upTo(maxBytes: 3), .tooManyBytesToLog(5)),
            (HTTPBody("Hello"), .upTo(maxBytes: 5), .complete(Data("Hello".utf8))),
        ] {
            let (bodyToLog, _) = try await bodyLoggingPolicy.process(body)
            XCTAssertEqual(bodyToLog, expectedMessage)
        }
    }
}
#endif  // canImport(Darwin)
