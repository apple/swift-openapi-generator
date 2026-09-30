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
                input: String, category: ContentType.Category, type: String, subtype: String, parameters: String,
                lowercasedOutput: String, originallyCasedOutput: String, originallyCasedOutputWithParameters: String
            )] = [
                (
                    "application/json", .json, "application", "json", "", "application/json", "application/json",
                    "application/json"
                ),
                (
                    "APPLICATION/JSON", .json, "application", "json", "", "application/json", "APPLICATION/JSON",
                    "APPLICATION/JSON"
                ),
                (
                    "application/json; charset=utf-8", .json, "application", "json", "; charset=utf-8",
                    "application/json", "application/json", "application/json; charset=utf-8"
                ),
                (
                    "application/x-www-form-urlencoded", .urlEncodedForm, "application", "x-www-form-urlencoded", "",
                    "application/x-www-form-urlencoded", "application/x-www-form-urlencoded",
                    "application/x-www-form-urlencoded"
                ),
                (
                    "multipart/form-data", .multipart, "multipart", "form-data", "", "multipart/form-data",
                    "multipart/form-data", "multipart/form-data"
                ), ("text/plain", .binary, "text", "plain", "", "text/plain", "text/plain", "text/plain"),
                ("*/*", .binary, "*", "*", "", "*/*", "*/*", "*/*"),
                (
                    "application/xml", .binary, "application", "xml", "", "application/xml", "application/xml",
                    "application/xml"
                ),
                (
                    "application/octet-stream", .binary, "application", "octet-stream", "", "application/octet-stream",
                    "application/octet-stream", "application/octet-stream"
                ),
                (
                    "application/myformat+json", .json, "application", "myformat+json", "", "application/myformat+json",
                    "application/myformat+json", "application/myformat+json"
                ), ("foo/bar", .binary, "foo", "bar", "", "foo/bar", "foo/bar", "foo/bar"),
                ("foo/bar+json", .json, "foo", "bar+json", "", "foo/bar+json", "foo/bar+json", "foo/bar+json"),
                (
                    "foo/bar+json; param1=a; param2=b", .json, "foo", "bar+json", "; param1=a; param2=b",
                    "foo/bar+json", "foo/bar+json", "foo/bar+json; param1=a; param2=b"
                ),
            ]
        for (
            rawValue, category, type, subtype, parameters, lowercasedTypeAndSubtype, originallyCasedTypeAndSubtype,
            originallyCasedOutputWithParameters
        ) in cases {
            let contentType = try ContentType(string: rawValue)
            XCTAssertEqual(contentType.category, category)
            XCTAssertEqual(contentType.lowercasedType, type)
            XCTAssertEqual(contentType.lowercasedSubtype, subtype)
            XCTAssertEqual(contentType.lowercasedParametersString, parameters)
            XCTAssertEqual(contentType.lowercasedTypeAndSubtype, lowercasedTypeAndSubtype)
            XCTAssertEqual(contentType.originallyCasedTypeAndSubtype, originallyCasedTypeAndSubtype)
            XCTAssertEqual(contentType.originallyCasedTypeSubtypeAndParameters, originallyCasedOutputWithParameters)
        }
    }

    func testHeaderValues() throws {
        let cases: [(input: String, forSending: String, forValidation: String)] = [
            ("application/json", "application/json; charset=utf-8", "application/json"),
            ("APPLICATION/JSON", "application/json; charset=utf-8", "application/json"),
            ("application/json; charset=utf-8", "application/json; charset=utf-8", "application/json; charset=utf-8"),
            // Parameter names are case-insensitive, but values are case-sensitive.
            ("application/json;charset=UTF-8", "application/json; charset=UTF-8", "application/json; charset=UTF-8"),
            ("application/json; CHARSET=UTF-8", "application/json; charset=UTF-8", "application/json; charset=UTF-8"),
            ("application/json; foo=Bar", "application/json; foo=Bar; charset=utf-8", "application/json; foo=Bar"),
            ("text/plain; charset=UTF-8", "text/plain; charset=UTF-8", "text/plain; charset=UTF-8"),
            ("Foo/Bar", "foo/bar", "foo/bar"),
        ]
        for (input, forSending, forValidation) in cases {
            let contentType = try ContentType(string: input)
            XCTAssertEqual(contentType.headerValueForSending, forSending, "Input: \(input)")
            XCTAssertEqual(contentType.headerValueForValidation, forValidation, "Input: \(input)")
        }
    }
}
