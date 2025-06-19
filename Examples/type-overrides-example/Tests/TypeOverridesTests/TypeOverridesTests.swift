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

@testable import TypeOverrides

final class TypeOverridesTests: XCTestCase {
    func testTypeWasOverriden() throws {
        let user = try JSONDecoder().decode(
            Components.Schemas.User.self, 
            from: Data(#"{"favoritePrimeNumber":23}"#.utf8)
        )
        XCTAssertEqual(user.favoritePrimeNumber.rawValue, 23)
        // This validates, at build time, that the type was overriden.
        let _: CustomPrimeNumber = user.favoritePrimeNumber
    }
}
