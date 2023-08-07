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
import OpenAPIKit30
@testable import _OpenAPIGeneratorCore

final class Test_ContentType: Test_Core {

    func testDecoding() throws {
        let cases: [(String, ContentType.Category)] = [
            ("application/json", .json),
            ("application/x-www-form-urlencoded", .binary),
            ("multipart/form-data", .binary),
            ("text/plain", .text),
            ("*/*", .binary),
            ("application/xml", .binary),
            ("application/octet-stream", .binary),
            ("application/myformat+json", .json),
            ("foo/bar", .binary),
        ]
        for (rawValue, category) in cases {
            let contentType = ContentType(rawValue)
            XCTAssertEqual(contentType.category, category)
            XCTAssertEqual(contentType.rawMIMEType, rawValue)
        }
    }
}
