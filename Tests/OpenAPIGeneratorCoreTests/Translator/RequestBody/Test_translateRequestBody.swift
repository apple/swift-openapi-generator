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

final class Test_translateRequestBody_Types: Test_Core {
    func testRequestBodyContentCase() throws {
        let translator = makeTypesTranslator()

        let bodyTypeName = TypeName(
            swiftKeyPath: ["Body"]
        )

        let contentTypeName = bodyTypeName.appending(
            swiftComponent: "Foo"
        )
        let contentTypeUsage = contentTypeName.asUsage

        let expected: [(TypeUsage, String)] = [
            // Required
            (contentTypeUsage, "Body.Foo"),

            // Optional
            (contentTypeUsage.asOptional, "Body.Foo"),
        ]

        for (typeUsage, associatedType) in expected {
            let decls = try translator.requestBodyContentCase(
                for: .init(
                    request: .init(content: [
                        .json: .init(schema: .string)
                    ]),
                    typeUsage: bodyTypeName.asUsage,
                    isInlined: false,
                    content: .init(
                        content: .init(
                            contentType: .applicationJSON,
                            schema: .schema(.string)
                        ),
                        typeUsage: typeUsage
                    )
                )
            )
            XCTAssertEqual(decls.count, 1)
            let decl = decls[0]
            let expected: Declaration = .enumCase(
                name: "json",
                kind: .nameWithAssociatedValues([
                    .init(type: associatedType)
                ])
            )
            XCTAssertEqualCodable(decl, expected)
        }
    }
}
