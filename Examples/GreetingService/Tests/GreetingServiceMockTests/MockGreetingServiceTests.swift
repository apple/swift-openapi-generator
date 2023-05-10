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
import XCTest
@testable import GreetingService

final class GreetingServiceMockTests: XCTestCase {
    func testWithMock() async throws {
        let client: APIProtocol = MockGreetingService()
        let response = try await client.getGreeting(.init(query: .init(name: "Jane")))
        XCTAssertEqual(response, .ok(.init(body: .json(.init(message: "(mock) Hello, Jane")))))
    }
}
