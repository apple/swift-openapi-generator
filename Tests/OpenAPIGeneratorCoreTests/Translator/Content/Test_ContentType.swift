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
import OpenAPIKit
@testable import _OpenAPIGeneratorCore

final class Test_ContentType: Test_Core {

    func testDecoding() throws {
        let cases:
            [(
                input: String, category: ContentType.Category, type: String, subtype: String, lowercasedOutput: String,
                originallyCasedOutput: String
            )] = [
                ("application/json", .json, "application", "json", "application/json", "application/json"),
                ("APPLICATION/JSON", .json, "application", "json", "application/json", "APPLICATION/JSON"),
                (
                    "application/json; charset=utf-8", .json, "application", "json", "application/json",
                    "application/json"
                ),
                (
                    "application/x-www-form-urlencoded", .binary, "application", "x-www-form-urlencoded",
                    "application/x-www-form-urlencoded", "application/x-www-form-urlencoded"
                ),
                (
                    "multipart/form-data", .binary, "multipart", "form-data", "multipart/form-data",
                    "multipart/form-data"
                ), ("text/plain", .text, "text", "plain", "text/plain", "text/plain"),
                ("*/*", .binary, "*", "*", "*/*", "*/*"),
                ("application/xml", .binary, "application", "xml", "application/xml", "application/xml"),
                (
                    "application/octet-stream", .binary, "application", "octet-stream", "application/octet-stream",
                    "application/octet-stream"
                ),
                (
                    "application/myformat+json", .json, "application", "myformat+json", "application/myformat+json",
                    "application/myformat+json"
                ), ("foo/bar", .binary, "foo", "bar", "foo/bar", "foo/bar"),
                ("foo/bar+json", .json, "foo", "bar+json", "foo/bar+json", "foo/bar+json"),
            ]
        for (rawValue, category, type, subtype, lowercasedTypeAndSubtype, originallyCasedTypeAndSubtype) in cases {
            let contentType = ContentType(rawValue)
            XCTAssertEqual(contentType.category, category)
            XCTAssertEqual(contentType.lowercasedType, type)
            XCTAssertEqual(contentType.lowercasedSubtype, subtype)
            XCTAssertEqual(contentType.lowercasedTypeAndSubtype, lowercasedTypeAndSubtype)
            XCTAssertEqual(contentType.originallyCasedTypeAndSubtype, originallyCasedTypeAndSubtype)
        }
    }
}
