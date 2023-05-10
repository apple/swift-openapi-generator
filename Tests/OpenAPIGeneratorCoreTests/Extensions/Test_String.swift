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
@testable import _OpenAPIGeneratorCore

final class Test_String: Test_Core {

    func testAsSwiftSafeName() {
        let cases: [(String, String)] = [
            // Simple
            ("foo", "foo"),

            // Starts with a number
            ("3foo", "_3foo"),

            // Keyword
            ("default", "_default"),

            // Reserved name
            ("Type", "_Type"),
        ]
        for (input, sanitized) in cases {
            XCTAssertEqual(input.asSwiftSafeName, sanitized)
        }
    }
}
