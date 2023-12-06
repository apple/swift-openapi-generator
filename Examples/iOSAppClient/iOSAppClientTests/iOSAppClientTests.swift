//
//  iOSAppClientTests.swift
//  iOSAppClientTests
//

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
