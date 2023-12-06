//
//  iOSAppClientTests.swift
//  iOSAppClientTests
//

import XCTest
@testable import iOSAppClient

final class iOSAppClientTests: XCTestCase {

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMockClient() async throws {
        let mockClient = MockClient()
        let response = try await mockClient.getGreeting(query: .init(name: "Test"))
        let message = try response.ok.body.json.message
        XCTAssertEqual(message, "(Mock) Hello, Test!")
    }
}
