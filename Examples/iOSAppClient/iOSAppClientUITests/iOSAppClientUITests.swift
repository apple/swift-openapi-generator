//
//  iOSAppClientUITests.swift
//  iOSAppClientUITests
//

import XCTest

final class iOSAppClientUITests: XCTestCase {

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
