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
@testable import CuratedLibraryClient

final class CuratedLibraryClientTests: XCTestCase {

    func testSuccess() async throws {
        let client = GreetingClient(underlyingClient: TestClient())
        let greeting = try await client.getGreeting(name: "Test")
        XCTAssertEqual(greeting, "(Test) Hello, Test!")
    }

    func testFailure() async throws {
        let client = GreetingClient(underlyingClient: TestClient(shouldFail: true))
        do {
            _ = try await client.getGreeting(name: "Test")
            XCTFail("Should have thrown an error.")
        } catch {
            guard let error = error as? TestClient.TestError else {
                XCTFail("Received an unexpected error.")
                return
            }
            XCTAssertEqual(error, TestClient.TestError(name: "Test"))
        }
    }
}

/// A test client that allows simulating failures.
struct TestClient: APIProtocol {

    /// A Boolean value indicating whether every method should throw an error.
    var shouldFail: Bool = false
    /// A test error that records the provided input name.
    struct TestError: Error, Hashable {

        /// The greeting name.
        var name: String?
    }

    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        guard !shouldFail else { throw TestError(name: input.query.name) }
        let name = input.query.name ?? "Stranger"
        return .ok(.init(body: .json(.init(message: "(Test) Hello, \(name)!"))))
    }
}
