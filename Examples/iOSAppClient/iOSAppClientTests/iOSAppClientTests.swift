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
@testable import iOSAppClient

final class iOSAppClientTests: XCTestCase {

    func testMockClient() async throws {
        let mockClient = MockClient()
        let response = try await mockClient.getGreeting(query: .init(name: "Test"))
        let message = try response.ok.body.json.message
        XCTAssertEqual(message, "(Mock) Hello, Test!")
    }
}
