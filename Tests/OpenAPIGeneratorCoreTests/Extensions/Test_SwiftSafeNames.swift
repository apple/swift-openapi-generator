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

final class Test_SwiftSafeNames: Test_Core {
    func testAsSwiftSafeName() {
        let cases: [(original: String, defensive: String, idiomaticUpper: String, idiomaticLower: String)] = [

            // Simple
            ("foo", "foo", "Foo", "foo"),

            // Space
            ("Hello world", "Hello_space_world", "HelloWorld", "helloWorld"),

            // Mixed capitalization
            ("My_URL_value", "My_URL_value", "MyURLValue", "myURLValue"),

            // Dashes
            ("hello-world", "hello_hyphen_world", "HelloWorld", "helloWorld"),

            // Header names
            ("Retry-After", "Retry_hyphen_After", "RetryAfter", "retryAfter"),

            // All uppercase
            ("HELLO_WORLD", "HELLO_WORLD", "HelloWorld", "helloWorld"), ("HELLO", "HELLO", "Hello", "hello"),

            // Acronyms
            ("HTTPProxy", "HTTPProxy", "HTTPProxy", "httpProxy"),
            ("HTTP_Proxy", "HTTP_Proxy", "HTTPProxy", "httpProxy"),
            ("HTTP_proxy", "HTTP_proxy", "HTTPProxy", "httpProxy"),
            ("OneHTTPProxy", "OneHTTPProxy", "OneHTTPProxy", "oneHTTPProxy"), ("iOS", "iOS", "IOS", "iOS"),
            // Numbers
            ("version 2.0", "version_space_2_period_0", "Version2_0", "version2_0"),
            ("V1.2Release", "V1_period_2Release", "V1_2Release", "v1_2Release"),

            // Synthesized operationId from method + path
            (
                "get/pets/{petId}/notifications", "get_sol_pets_sol__lcub_petId_rcub__sol_notifications",
                "GetPetsPetIdNotifications", "getPetsPetIdNotifications"
            ),
            (
                "get/name/v{version}.zip", "get_sol_name_sol_v_lcub_version_rcub__period_zip", "GetNameVversion_zip",
                "getNameVversion_zip"
            ),

            // Technical strings
            ("file/path/to/resource", "file_sol_path_sol_to_sol_resource", "FilePathToResource", "filePathToResource"),
            (
                "user.name@domain.com", "user_period_name_commat_domain_period_com", "User_name_commat_domain_com",
                "user_name_commat_domain_com"
            ), ("hello.world.2023", "hello_period_world_period_2023", "Hello_world_2023", "hello_world_2023"),
            ("order#123", "order_num_123", "Order_num_123", "order_num_123"),
            ("pressKeys#123", "pressKeys_num_123", "PressKeys_num_123", "pressKeys_num_123"),

            // Non-English characters
            ("naïve café", "naïve_space_café", "NaïveCafé", "naïveCafé"),

            // Starts with a number
            ("3foo", "_3foo", "_3foo", "_3foo"),

            // Keyword
            ("default", "_default", "Default", "_default"),

            // Reserved name
            ("Type", "_Type", "_Type", "_type"),

            // Empty string
            ("", "_empty", "_Empty_", "_empty_"),

            // Special Char in middle
            ("inv@lidName", "inv_commat_lidName", "Inv_commat_lidName", "inv_commat_lidName"),

            // Special Char in first position
            ("!nvalidName", "_excl_nvalidName", "_excl_nvalidName", "_excl_nvalidName"),

            // Special Char in last position
            ("invalidNam?", "invalidNam_quest_", "InvalidNam_quest_", "invalidNam_quest_"),

            // Preserve leading underscores
            ("__user_name", "__user_name", "__UserName", "__userName"),

            // Preserve only leading underscores
            ("user__name", "user__name", "UserName", "userName"),

            // Invalid underscore case
            ("_", "_underscore_", "_underscore_", "_underscore_"),

            // Special character mixed with character not in map
            ("$nake…", "_dollar_nake_x2026_", "_dollar_nake_x2026_", "_dollar_nake_x2026_"),

            // Only special character
            ("$", "_dollar_", "_dollar_", "_dollar_"),

            // Only special character not in map
            ("……", "_x2026__x2026_", "_x2026__x2026_", "_x2026__x2026_"),

            // Non Latin Characters combined with a RTL language
            ("$مرحبا", "_dollar_مرحبا", "_dollar_مرحبا", "_dollar_مرحبا"),

            // Emoji
            ("heart❤️emoji", "heart_x2764_️emoji", "Heart_x2764_️emoji", "heart_x2764_️emoji"),

            // Content type components
            ("application", "application", "Application", "application"),
            ("vendor1+json", "vendor1_plus_json", "Vendor1Json", "vendor1Json"),

            // Known real-world examples
            ("+1", "_plus_1", "_plus_1", "_plus_1"), ("one+two", "one_plus_two", "OneTwo", "oneTwo"),
            ("-1", "_hyphen_1", "_hyphen_1", "_hyphen_1"), ("one-two", "one_hyphen_two", "OneTwo", "oneTwo"),

            // Override
            ("MEGA", "m_e_g_a", "m_e_g_a", "m_e_g_a"),
        ]
        self.continueAfterFailure = true
        do {
            let translator = makeTranslator(nameOverrides: ["MEGA": "m_e_g_a"])
            let safeNameGenerator = translator.context.safeNameGenerator
            for (input, sanitizedDefensive, _, _) in cases {
                XCTAssertEqual(
                    safeNameGenerator.swiftMemberName(for: input),
                    sanitizedDefensive,
                    "Defensive, input: \(input)"
                )
            }
        }
        do {
            let translator = makeTranslator(namingStrategy: .idiomatic, nameOverrides: ["MEGA": "m_e_g_a"])
            let safeNameGenerator = translator.context.safeNameGenerator
            for (input, _, idiomaticUpper, idiomaticLower) in cases {
                XCTAssertEqual(
                    safeNameGenerator.swiftTypeName(for: input),
                    idiomaticUpper,
                    "Idiomatic upper, input: \(input)"
                )
                XCTAssertEqual(
                    safeNameGenerator.swiftMemberName(for: input),
                    idiomaticLower,
                    "Idiomatic lower, input: \(input)"
                )
            }
        }
    }
}
