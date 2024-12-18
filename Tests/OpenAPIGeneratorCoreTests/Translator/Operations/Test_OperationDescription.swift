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
        let allParameters = try makeOperationDescription(pathItem)?.allParameters

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
        let allParameters = try makeOperationDescription(pathItem)?.allParameters

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
        let allParameters = try makeOperationDescription(pathItem)?.allParameters

        XCTAssertEqual(allParameters, [pathLevelParameter, duplicatedParameter, operationLevelParameter])
    }

    func testResponseOutcomes_without_default_response() {
        let responses: OpenAPI.Response.Map = [
            .status(code: 200): .b(.init(description: "200")), .status(code: 404): .b(.init(description: "404")),
        ]

        let pathItem = OpenAPI.PathItem(get: .init(requestBody: .b(.init(content: [:])), responses: responses))
        let responseOutcomes = makeOperationDescription(pathItem)?.responseOutcomes

        XCTAssertEqual(
            responseOutcomes,
            [
                OpenAPI.Operation.ResponseOutcome(status: responses[0].key, response: responses[0].value),
                OpenAPI.Operation.ResponseOutcome(status: responses[1].key, response: responses[1].value),
            ]
        )
    }

    func testResponseOutcomes_with_default_response_on_last() {
        let responses: OpenAPI.Response.Map = [
            .status(code: 200): .b(.init(description: "200")), .status(code: 404): .b(.init(description: "404")),
            .default: .b(.init(description: "default")),
        ]

        let pathItem = OpenAPI.PathItem(get: .init(requestBody: .b(.init(content: [:])), responses: responses))
        let responseOutcomes = makeOperationDescription(pathItem)?.responseOutcomes

        XCTAssertEqual(
            responseOutcomes,
            [
                OpenAPI.Operation.ResponseOutcome(status: responses[0].key, response: responses[0].value),
                OpenAPI.Operation.ResponseOutcome(status: responses[1].key, response: responses[1].value),
                OpenAPI.Operation.ResponseOutcome(status: responses[2].key, response: responses[2].value),
            ]
        )
    }

    func testResponseOutcomes_with_default_response_on_first() {
        let responses: OpenAPI.Response.Map = [
            .default: .b(.init(description: "default")), .status(code: 200): .b(.init(description: "200")),
            .status(code: 404): .b(.init(description: "404")),
        ]

        let pathItem = OpenAPI.PathItem(get: .init(requestBody: .b(.init(content: [:])), responses: responses))
        let responseOutcomes = makeOperationDescription(pathItem)?.responseOutcomes

        XCTAssertEqual(
            responseOutcomes,
            [
                OpenAPI.Operation.ResponseOutcome(status: responses[1].key, response: responses[1].value),
                OpenAPI.Operation.ResponseOutcome(status: responses[2].key, response: responses[2].value),
                OpenAPI.Operation.ResponseOutcome(status: responses[0].key, response: responses[0].value),
            ]
        )
    }

    private func makeOperationDescription(_ pathItem: OpenAPI.PathItem) -> OperationDescription? {
        guard let endpoint = pathItem.endpoints.first else {
            XCTFail("Unable to retrieve the path item first endpoint.")
            return nil
        }

        return OperationDescription(
            path: .init(["/test"]),
            endpoint: endpoint,
            pathParameters: pathItem.parameters,
            components: .init(),
            context: .init(safeNameGenerator: .defensive)
        )
    }
}
