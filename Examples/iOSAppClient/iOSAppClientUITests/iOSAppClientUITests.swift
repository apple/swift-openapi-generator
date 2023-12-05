//
//  iOSAppClientUITests.swift
//  iOSAppClientUITests
//

import XCTest

final class iOSAppClientUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGreeting() throws {
        let app = XCUIApplication()
        // Comment out the following line to have the app running in the simulator try to connect
        // to the server running on your Mac.
        app.launchEnvironment["USE_MOCK_CLIENT"] = "true"
        app.launch()
        let textField = app.textFields["Name"]
        textField.tap()
        textField.doubleTap()
        textField.typeKey(XCUIKeyboardKey.delete.rawValue, modifierFlags: [])
        textField.typeText("Test")
        app.buttons["Refresh greeting"].tap()
        XCTAssertEqual(app.staticTexts["greeting-label"].label, "(Mock) Hello, Test!")
    }
}
