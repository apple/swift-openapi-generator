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
import OpenAPIKit
import XCTest
@testable import _OpenAPIGeneratorCore

final class Test_OperationDescription: Test_Core {

    func testAllParameters_duplicates_retainOnlyOperationParameters() throws {
        let pathLevelParameter = UnresolvedParameter.b(
            OpenAPI.Parameter(name: "test", context: .query(required: false), schema: .integer)
        )
        let operationLevelParameter = UnresolvedParameter.b(
            OpenAPI.Parameter(name: "test", context: .query(required: false), schema: .string)
        )

        let pathItem = OpenAPI.PathItem(
            parameters: [pathLevelParameter],
            get: .init(parameters: [operationLevelParameter], requestBody: .b(.init(content: [:])), responses: [:]),
            vendorExtensions: [:]
        )
        let allParameters = try _test(pathItem)

        XCTAssertEqual(allParameters, [operationLevelParameter])
    }

    func testAllParameters_duplicates_keepsDuplicatesFromDifferentLocation() throws {
        let pathLevelParameter = UnresolvedParameter.b(
            OpenAPI.Parameter(name: "test", context: .query(required: false), schema: .integer)
        )
        let operationLevelParameter = UnresolvedParameter.b(
            OpenAPI.Parameter(name: "test", context: .path, schema: .string)
        )

        let pathItem = OpenAPI.PathItem(
            parameters: [pathLevelParameter],
            get: .init(parameters: [operationLevelParameter], requestBody: .b(.init(content: [:])), responses: [:]),
            vendorExtensions: [:]
        )
        let allParameters = try _test(pathItem)

        XCTAssertEqual(allParameters, [pathLevelParameter, operationLevelParameter])
    }

    func testAllParameters_duplicates_ordering() throws {
        let pathLevelParameter = UnresolvedParameter.b(
            OpenAPI.Parameter(name: "test1", context: .query(required: false), schema: .integer)
        )
        let duplicatedParameter = UnresolvedParameter.b(
            OpenAPI.Parameter(name: "test2", context: .query(required: false), schema: .integer)
        )
        let operationLevelParameter = UnresolvedParameter.b(
            OpenAPI.Parameter(name: "test3", context: .query(required: false), schema: .string)
        )

        let pathItem = OpenAPI.PathItem(
            parameters: [pathLevelParameter, duplicatedParameter],
            get: .init(
                parameters: [duplicatedParameter, operationLevelParameter],
                requestBody: .b(.init(content: [:])),
                responses: [:]
            ),
            vendorExtensions: [:]
        )
        let allParameters = try _test(pathItem)

        XCTAssertEqual(allParameters, [pathLevelParameter, duplicatedParameter, operationLevelParameter])
    }

    private func _test(_ pathItem: OpenAPI.PathItem) throws -> [UnresolvedParameter] {
        guard let endpoint = pathItem.endpoints.first else {
            XCTFail("Unable to retrieve the path item first endpoint.")
            return []
        }

        let operationDescription = OperationDescription(
            path: .init(["/test"]),
            endpoint: endpoint,
            pathParameters: pathItem.parameters,
            components: .init(),
            asSwiftSafeName: { $0 }
        )

        return try operationDescription.allParameters
    }
}
