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

final class HelloWorldiOSClientAppUITests: XCTestCase {

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
