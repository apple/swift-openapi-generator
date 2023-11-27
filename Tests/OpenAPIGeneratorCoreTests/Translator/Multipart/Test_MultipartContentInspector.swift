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

class Test_MultipartContentInspector: Test_Core {
    func testSerializationStrategy() throws {
        let translator = makeTypesTranslator()
        func _test(
            schemaIn: JSONSchema,
            encoding: OpenAPI.Content.Encoding? = nil,
            source: MultipartPartInfo.ContentTypeSource,
            repetition: MultipartPartInfo.RepetitionKind,
            schemaOut: JSONSchema,
            file: StaticString = #file,
            line: UInt = #line
        ) throws {
            let (info, actualSchemaOut) = try XCTUnwrap(
                translator.parseMultipartPartInfo(schema: schemaIn, encoding: encoding, foundIn: "")
            )
            XCTAssertEqual(info.repetition, repetition, file: file, line: line)
            XCTAssertEqual(info.contentTypeSource, source, file: file, line: line)
            XCTAssertEqual(actualSchemaOut, schemaOut, file: file, line: line)
        }
        try _test(schemaIn: .object, source: .infer(.complex), repetition: .single, schemaOut: .object)
        try _test(schemaIn: .array(items: .object), source: .infer(.complex), repetition: .array, schemaOut: .object)
        try _test(
            schemaIn: .string,
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary)
        )
        try _test(
            schemaIn: .integer,
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary)
        )
        try _test(
            schemaIn: .boolean,
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary)
        )
        try _test(
            schemaIn: .string(allowedValues: ["foo"]),
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary)
        )
        try _test(
            schemaIn: .array(items: .string),
            source: .infer(.primitive),
            repetition: .array,
            schemaOut: .string(contentEncoding: .binary)
        )
        try _test(
            schemaIn: .any(of: .string, .string(allowedValues: ["foo"])),
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary)
        )
    }
}
