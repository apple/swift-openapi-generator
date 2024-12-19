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
    /// Setup method called before the invocation of each test method in the class.
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
    func roundtrip<T: Codable & Equatable>(_ value: T, verifyingJSON: String? = nil) throws -> T {
        let data = try testEncoder.encode(value)
        if let verifyingJSON { XCTAssertEqual(String(decoding: data, as: UTF8.self), verifyingJSON) }
        return try testDecoder.decode(T.self, from: data)
    }
    func _testRoundtrip<T: Codable & Equatable>(_ value: T, verifyingJSON: String? = nil) throws {
        let decodedValue = try roundtrip(value, verifyingJSON: verifyingJSON)
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
            Components.Schemas.MixedAnyOf(value2: .bigElephant1, value4: #"BIG_ELEPHANT_1"#),
            expectedJSON: #""BIG_ELEPHANT_1""#
        )
        try testJSON(
            Components.Schemas.MixedAnyOf(value3: .init(id: 1, name: "Fluffz")),
            expectedJSON: #"{"id":1,"name":"Fluffz"}"#
        )
        try testJSON(
            Components.Schemas.MixedOneOf.case1(Date(timeIntervalSince1970: 1_674_036_251)),
            expectedJSON: #""2023-01-18T10:04:11Z""#
        )
        try testJSON(Components.Schemas.MixedOneOf.PetKind(.bigElephant1), expectedJSON: #""BIG_ELEPHANT_1""#)
        try testJSON(
            Components.Schemas.MixedOneOf.Pet(.init(id: 1, name: "Fluffz")),
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
        try _testRoundtrip(Components.Schemas.OneOfObjectsWithDiscriminator.walk(.init(kind: "Walk", length: 1)))
        try _testRoundtrip(
            Components.Schemas.OneOfObjectsWithDiscriminator.messagedExercise(
                .init(value1: .init(kind: "MessagedExercise"), value2: .init(message: "hello"))
            )
        )
    }
    func testOneOfWithDiscriminator_invalidDiscriminator() throws {
        XCTAssertThrowsError(
            try testDecoder.decode(Components.Schemas.OneOfObjectsWithDiscriminator.self, from: Data(#"{}"#.utf8))
        )
        XCTAssertThrowsError(
            try testDecoder.decode(
                Components.Schemas.OneOfObjectsWithDiscriminator.self,
                from: Data(#"{"kind": "FooBar"}"#.utf8)
            )
        )
    }
    func testThrowingShorthandAPIs() throws {
        let created = Operations.CreatePet.Output.Created(body: .json(.init(id: 42, name: "Scruffy")))
        let output = Operations.CreatePet.Output.created(created)
        XCTAssertEqual(try output.created, created)
        XCTAssertThrowsError(try output.clientError) { error in
            guard case let .unexpectedResponseStatus(expectedStatus, actualOutput) = error as? RuntimeError,
                expectedStatus == "clientError", actualOutput as? Operations.CreatePet.Output == output
            else {
                XCTFail("Expected error, but not this: \(error)")
                return
            }
        }
        let stats = Components.Schemas.PetStats(count: 42)
        let ok = Operations.GetStats.Output.Ok(body: .json(stats))
        XCTAssertEqual(try ok.body.json, stats)
        XCTAssertThrowsError(try ok.body.plainText) { error in
            guard case let .unexpectedResponseBody(expectedContentType, actualBody) = error as? RuntimeError,
                expectedContentType == "text/plain", actualBody as? Operations.GetStats.Output.Ok.Body == .json(stats)
            else {
                XCTFail("Expected error, but not this: \(error)")
                return
            }
        }
    }
    func testRecursiveType_roundtrip() throws {
        try _testRoundtrip(
            Components.Schemas.RecursivePet(name: "C", parent: .init(name: "B", parent: .init(name: "A"))),
            verifyingJSON: #"{"name":"C","parent":{"name":"B","parent":{"name":"A"}}}"#
        )
    }
    func testRecursiveType_accessors_3levels() throws {
        var c = Components.Schemas.RecursivePet(name: "C", parent: .init(name: "B"))
        c.name = "C2"
        c.parent!.parent = .init(name: "A")
        XCTAssertEqual(c.parent, .init(name: "B", parent: .init(name: "A")))
        XCTAssertEqual(
            c,
            Components.Schemas.RecursivePet(name: "C2", parent: .init(name: "B", parent: .init(name: "A")))
        )
    }
    func testRecursiveType_accessors_2levels() throws {
        var b = Components.Schemas.RecursivePet(name: "B")
        b.name = "B2"
        b.parent = .init(name: "A")
        XCTAssertEqual(b.parent, .init(name: "A"))
        XCTAssertEqual(b, .init(name: "B2", parent: .init(name: "A")))
    }
    func testRecursiveNestedType_roundtrip() throws {
        try _testRoundtrip(
            Components.Schemas.RecursivePetNested(
                name: "C",
                parent: .init(nested: .init(name: "B", parent: .init(nested: .init(name: "A"))))
            ),
            verifyingJSON: #"{"name":"C","parent":{"nested":{"name":"B","parent":{"nested":{"name":"A"}}}}}"#
        )
    }
    func testServers_1() throws { XCTAssertEqual(try Servers.Server1.url(), URL(string: "https://example.com/api")) }
    func testServers_2() throws { XCTAssertEqual(try Servers.Server2.url(), URL(string: "/api")) }
    func testServers_3() throws {
        XCTAssertEqual(try Servers.Server3.url(), URL(string: "https://test.example.com:443/v1"))
        XCTAssertEqual(
            try Servers.Server3.url(subdomain: "bar", port: ._8443, basePath: "v2/staging"),
            URL(string: "https://bar.example.com:8443/v2/staging")
        )
    }
}
