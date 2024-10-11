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

            // Empty string
            ("", "_empty"),

            // Special Char in middle
            ("inv@lidName", "inv_commat_lidName"),

            // Special Char in first position
            ("!nvalidName", "_excl_nvalidName"),

            // Special Char in last position
            ("invalidNam?", "invalidNam_quest_"),

            // Valid underscore case
            ("__user", "__user"),

            // Invalid underscore case
            ("_", "_underscore_"),

            // Special character mixed with character not in map
            ("$nake…", "_dollar_nake_x2026_"),

            // Only special character
            ("$", "_dollar_"),

            // Only special character not in map
            ("……", "_x2026__x2026_"),

            // Non Latin Characters
            ("$مرحبا", "_dollar_مرحبا"),

            // Content type components
            ("application", "application"), ("vendor1+json", "vendor1_plus_json"),
        ]
        let translator = makeTranslator()
        let asSwiftSafeName: (String) -> String = translator.context.asSwiftSafeName
        for (input, sanitized) in cases { XCTAssertEqual(asSwiftSafeName(input), sanitized) }
    }
}
