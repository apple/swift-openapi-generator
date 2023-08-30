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
import OpenAPIRuntime
import PetstoreConsumerTestCore

final class Test_Types: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    func testStructCodingKeys() throws {
        let cases: [(Components.Schemas._Error.CodingKeys, String)] = [(.code, "code"), (.me_dollar_sage, "me$sage")]
        for (value, rawValue) in cases { XCTAssertEqual(value.rawValue, rawValue) }
    }

    func testEnumCoding() throws {
        let cases: [(Components.Schemas.PetKind, String)] = [(.cat, "cat"), (._dollar_nake, "$nake")]
        for (value, rawValue) in cases { XCTAssertEqual(value.rawValue, rawValue) }
    }

    var testEncoder: JSONEncoder { .init() }

    var testDecoder: JSONDecoder { .init() }

    func roundtrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try testEncoder.encode(value)
        return try testDecoder.decode(T.self, from: data)
    }

    func _testRoundtrip<T: Codable & Equatable>(_ value: T) throws {
        let decodedValue = try roundtrip(value)
        XCTAssertEqual(decodedValue, value)
    }

    func testNoAdditionalPropertiesCoding_roundtrip() throws {
        try _testRoundtrip(Components.Schemas.NoAdditionalProperties(foo: "hi"))
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
        try _testRoundtrip(Components.Schemas.AnyAdditionalProperties(foo: "hi", additionalProperties: .init()))
    }

    func testAnyAdditionalPropertiesCoding_roundtrip_withExtraProperty() throws {
        try _testRoundtrip(
            Components.Schemas.AnyAdditionalProperties(
                foo: "hi",
                additionalProperties: .init(unvalidatedValue: ["hello": 1])
            )
        )
    }

    func testTypedAdditionalPropertiesCoding_roundtrip_noExtraProperty() throws {
        try _testRoundtrip(Components.Schemas.TypedAdditionalProperties(foo: "hi", additionalProperties: [:]))
    }

    func testTypedAdditionalPropertiesCoding_roundtrip_withExtraProperty() throws {
        try _testRoundtrip(Components.Schemas.TypedAdditionalProperties(foo: "hi", additionalProperties: ["hello": 1]))
    }

    func testAllOf_roundtrip() throws {
        try _testRoundtrip(Components.Schemas.AllOfObjects(value1: .init(message: "hi"), value2: .init(code: 1)))
    }

    func testAllOf_missingProperty() throws {
        XCTAssertThrowsError(try testDecoder.decode(Components.Schemas.AllOfObjects.self, from: Data(#"{}"#.utf8)))
        XCTAssertThrowsError(
            try testDecoder.decode(Components.Schemas.AllOfObjects.self, from: Data(#"{"message":"hi"}"#.utf8))
        )
        XCTAssertThrowsError(
            try testDecoder.decode(Components.Schemas.AllOfObjects.self, from: Data(#"{"code":1}"#.utf8))
        )
    }

    func testAnyOf_roundtrip() throws {
        try _testRoundtrip(Components.Schemas.AnyOfObjects(value1: .init(message: "hi"), value2: .init(code: 1)))
        try _testRoundtrip(Components.Schemas.AnyOfObjects(value1: .init(message: "hi"), value2: nil))
        try _testRoundtrip(Components.Schemas.AnyOfObjects(value1: nil, value2: .init(code: 1)))
    }

    func testAnyOf_allFailedToDecode() throws {
        XCTAssertThrowsError(try testDecoder.decode(Components.Schemas.AnyOfObjects.self, from: Data(#"{}"#.utf8)))
    }

    func testOneOfAny_roundtrip() throws {
        try _testRoundtrip(Components.Schemas.OneOfAny.case1("hi"))
        try _testRoundtrip(Components.Schemas.OneOfAny.case2(1))
        try _testRoundtrip(Components.Schemas.OneOfAny.CodeError(.init(code: 2)))
        try _testRoundtrip(Components.Schemas.OneOfAny.case4(.init(message: "hello")))
    }

    func testOneOfWithDiscriminator_roundtrip() throws {
        try _testRoundtrip(Components.Schemas.OneOfObjectsWithDiscriminator.Walk(.init(kind: "Walk", length: 1)))
        try _testRoundtrip(
            Components.Schemas.OneOfObjectsWithDiscriminator.MessagedExercise(
                .init(value1: .init(kind: "MessagedExercise"), value2: .init(message: "hello"))
            )
        )
    }

    func testOneOfWithDiscriminator_invalidDiscriminator() throws {
        XCTAssertThrowsError(
            try testDecoder.decode(Components.Schemas.OneOfObjectsWithDiscriminator.self, from: Data(#"{}"#.utf8))
        )
    }
}
