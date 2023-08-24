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

final class Test_ContentSwiftName: Test_Core {

    func test() throws {
        let nameMaker = makeTranslator().contentSwiftName
        let cases: [(String, String)] = [

            // Short names.
            ("application/json", "json"),
            ("application/x-www-form-urlencoded", "urlEncodedForm"),
            ("multipart/form-data", "multipartForm"),
            ("text/plain", "plainText"),
            ("*/*", "any"),
            ("application/xml", "xml"),
            ("application/octet-stream", "binary"),
            ("text/html", "html"),
            ("application/yaml", "yaml"),
            ("text/csv", "csv"),
            ("image/png", "png"),
            ("application/pdf", "pdf"),
            ("image/jpeg", "jpeg"),

            // Generic names.
            ("application/myformat+json", "application_myformat_plus_json"),
            ("foo/bar", "foo_bar"),
        ]
        for item in cases {
            let contentType = try XCTUnwrap(ContentType(item.0))
            XCTAssertEqual(nameMaker(contentType), item.1, "Case \(item.0) failed")
        }
    }
}
