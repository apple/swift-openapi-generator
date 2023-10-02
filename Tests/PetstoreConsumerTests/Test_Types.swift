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
@testable import OpenAPIRuntime
import PetstoreConsumerTestCore

final class Test_Types: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    func testStructCodingKeys() throws {
        let cases: [(Components.Schemas._Error.CodingKeys, String)] = [
            (.code, "code"),
            (.me_dollar_sage, "me$sage"),
        ]
        for (value, rawValue) in cases {
            XCTAssertEqual(value.rawValue, rawValue)
        }
    }

    func testEnumCoding() throws {
        let cases: [(Components.Schemas.PetKind, String)] = [
            (.cat, "cat"),
            (._dollar_nake, "$nake"),
        ]
        for (value, rawValue) in cases {
            XCTAssertEqual(value.rawValue, rawValue)
        }
    }

    var testEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    var testDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func roundtrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try testEncoder.encode(value)
        return try testDecoder.decode(T.self, from: data)
    }

    func _testRoundtrip<T: Codable & Equatable>(_ value: T) throws {
        let decodedValue = try roundtrip(value)
        XCTAssertEqual(decodedValue, value)
    }

    func testNoAdditionalPropertiesCoding_roundtrip() throws {
        try _testRoundtrip(
            Components.Schemas.NoAdditionalProperties(foo: "hi")
        )
    }

    func testNoAdditionalPropertiesCoding_extraProperty() throws {
        XCTAssertThrowsError(
            try testDecoder.decode(
                Components.Schemas.NoAdditionalProperties.self,
                from: Data(#"{"foo":"hi","hello":1}"#.utf8)
            )
        )
    }

    func testAnyAdditionalPropertiesCoding_roundtrip_noExtraProperty() throws {
        try _testRoundtrip(
            Components.Schemas.AnyAdditionalProperties(
                foo: "hi",
                additionalProperties: .init()
            )
        )
    }

    func testAnyAdditionalPropertiesCoding_roundtrip_withExtraProperty() throws {
        try _testRoundtrip(
            Components.Schemas.AnyAdditionalProperties(
                foo: "hi",
                additionalProperties: .init(unvalidatedValue: [
                    "hello": 1
                ])
            )
        )
    }

    func testTypedAdditionalPropertiesCoding_roundtrip_noExtraProperty() throws {
        try _testRoundtrip(
            Components.Schemas.TypedAdditionalProperties(
                foo: "hi",
                additionalProperties: [:]
            )
        )
    }

    func testTypedAdditionalPropertiesCoding_roundtrip_withExtraProperty() throws {
        try _testRoundtrip(
            Components.Schemas.TypedAdditionalProperties(
                foo: "hi",
                additionalProperties: [
                    "hello": 1
                ]
            )
        )
    }

    func testAllOf_roundtrip() throws {
        try _testRoundtrip(
            Components.Schemas.AllOfObjects(
                value1: .init(message: "hi"),
                value2: .init(code: 1)
            )
        )
    }

    func testAllAnyOneOf_withDate_roundtrip() throws {
        func testJSON<T: Codable & Equatable>(
            _ value: T,
            expectedJSON: String,
            file: StaticString = #file,
            line: UInt = #line
        ) throws {
            let data = try testEncoder.encode(value)
            XCTAssertEqual(String(decoding: data, as: UTF8.self), expectedJSON, file: file, line: line)
            let decodedValue = try testDecoder.decode(T.self, from: data)
            XCTAssertEqual(decodedValue, value, file: file, line: line)
        }

        try testJSON(
            Components.Schemas.MixedAnyOf(
                value1: Date(timeIntervalSince1970: 1_674_036_251),
                value4: #"2023-01-18T10:04:11Z"#
            ),
            expectedJSON: #""2023-01-18T10:04:11Z""#
        )
        try testJSON(
            Components.Schemas.MixedAnyOf(
                value2: .BIG_ELEPHANT_1,
                value4: #"BIG_ELEPHANT_1"#
            ),
            expectedJSON: #""BIG_ELEPHANT_1""#
        )
        try testJSON(
            Components.Schemas.MixedAnyOf(
                value3: .init(id: 1, name: "Fluffz")
            ),
            expectedJSON: #"{"id":1,"name":"Fluffz"}"#
        )

        try testJSON(
            Components.Schemas.MixedOneOf.case1(
                Date(timeIntervalSince1970: 1_674_036_251)
            ),
            expectedJSON: #""2023-01-18T10:04:11Z""#
        )
        try testJSON(
            Components.Schemas.MixedOneOf.PetKind(
                .BIG_ELEPHANT_1
            ),
            expectedJSON: #""BIG_ELEPHANT_1""#
        )
        try testJSON(
            Components.Schemas.MixedOneOf.Pet(
                .init(id: 1, name: "Fluffz")
            ),
            expectedJSON: #"{"id":1,"name":"Fluffz"}"#
        )

        try testJSON(
            Components.Schemas.MixedAllOfPrimitive(
                value1: Date(timeIntervalSince1970: 1_674_036_251),
                value2: #"2023-01-18T10:04:11Z"#
            ),
            expectedJSON: #""2023-01-18T10:04:11Z""#
        )
    }

    func testAllOf_missingProperty() throws {
        XCTAssertThrowsError(
            try testDecoder.decode(
                Components.Schemas.AllOfObjects.self,
                from: Data(#"{}"#.utf8)
            )
        )
        XCTAssertThrowsError(
            try testDecoder.decode(
                Components.Schemas.AllOfObjects.self,
                from: Data(#"{"message":"hi"}"#.utf8)
            )
        )
        XCTAssertThrowsError(
            try testDecoder.decode(
                Components.Schemas.AllOfObjects.self,
                from: Data(#"{"code":1}"#.utf8)
            )
        )
    }

    func testAnyOf_roundtrip() throws {
        try _testRoundtrip(
            Components.Schemas.AnyOfObjects(
                value1: .init(message: "hi"),
                value2: .init(code: 1)
            )
        )
        try _testRoundtrip(
            Components.Schemas.AnyOfObjects(
                value1: .init(message: "hi"),
                value2: nil
            )
        )
        try _testRoundtrip(
            Components.Schemas.AnyOfObjects(
                value1: nil,
                value2: .init(code: 1)
            )
        )
    }

    func testAnyOf_allFailedToDecode() throws {
        XCTAssertThrowsError(
            try testDecoder.decode(
                Components.Schemas.AnyOfObjects.self,
                from: Data(#"{}"#.utf8)
            )
        )
    }

    func testOneOfAny_roundtrip() throws {
        try _testRoundtrip(
            Components.Schemas.OneOfAny.case1("hi")
        )
        try _testRoundtrip(
            Components.Schemas.OneOfAny.case2(1)
        )
        try _testRoundtrip(
            Components.Schemas.OneOfAny.CodeError(.init(code: 2))
        )
        try _testRoundtrip(
            Components.Schemas.OneOfAny.case4(.init(message: "hello"))
        )
    }

    func testOneOfWithDiscriminator_roundtrip() throws {
        try _testRoundtrip(
            Components.Schemas.OneOfObjectsWithDiscriminator
                .Walk(
                    .init(
                        kind: "Walk",
                        length: 1
                    )
                )
        )
        try _testRoundtrip(
            Components.Schemas.OneOfObjectsWithDiscriminator
                .MessagedExercise(
                    .init(
                        value1: .init(kind: "MessagedExercise"),
                        value2: .init(message: "hello")
                    )
                )
        )
    }

    func testOneOfWithDiscriminator_invalidDiscriminator() throws {
        XCTAssertThrowsError(
            try testDecoder.decode(
                Components.Schemas.OneOfObjectsWithDiscriminator.self,
                from: Data(#"{}"#.utf8)
            )
        )
    }

    func testThrowingShorthandAPIs() throws {
        let created = Operations.createPet.Output.Created(body: .json(.init(id: 42, name: "Scruffy")))
        let output = Operations.createPet.Output.created(created)
        XCTAssertEqual(try output.created, created)
        XCTAssertThrowsError(try output.clientError) { error in
            guard
                case let .unexpectedResponseStatus(expectedStatus, actualOutput) = error as? RuntimeError,
                expectedStatus == "clientError",
                actualOutput as? Operations.createPet.Output == output
            else {
                XCTFail("Expected error, but not this: \(error)")
                return
            }
        }

        let plainTextOK = Operations.getStats.Output.Ok(body: .plainText("stats"))
        XCTAssertEqual(try plainTextOK.body.plainText, "stats")
        XCTAssertThrowsError(try plainTextOK.body.json) { error in
            guard
                case let .unexpectedResponseBody(expectedContentType, actualBody) = error as? RuntimeError,
                expectedContentType == "application/json; charset=utf-8",
                actualBody as? Operations.getStats.Output.Ok.Body == .plainText("stats")
            else {
                XCTFail("Expected error, but not this: \(error)")
                return
            }
        }
    }
}
