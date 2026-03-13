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
import Testing
@testable import _OpenAPIGeneratorCore


@Suite("Multipart Content Inspector")
struct Test_MultipartContentInspector {
    
    private func _test(
        schemaIn: JSONSchema,
        encoding: OpenAPI.Content.Encoding? = nil,
        source: MultipartPartInfo.ContentTypeSource,
        repetition: MultipartPartInfo.RepetitionKind,
        schemaOut: JSONSchema,
        translator: TypesFileTranslator
    ) throws {
        let result = try translator.parseMultipartPartInfo(schema: schemaIn, encoding: encoding, foundIn: "")
        #expect(result != nil)
        
        let (info, actualSchemaOut) = result!
        #expect(info.repetition == repetition)
        #expect(info.contentTypeSource == source)
        #expect(actualSchemaOut == schemaOut)
    }
    
    @Test("Serialization Strategy Tests")
    func testSerializationStrategy() throws {
        let translator = TestFixtures.makeTypesTranslator()
        
        try _test(
            schemaIn: .object,
            source: .infer(.complex),
            repetition: .single,
            schemaOut: .object,
            translator: translator
        )
        
        try _test(
            schemaIn: .array(items: .object),
            source: .infer(.complex),
            repetition: .array,
            schemaOut: .object,
            translator: translator
        )
        
        try _test(
            schemaIn: .string,
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary),
            translator: translator
        )
        
        try _test(
            schemaIn: .integer,
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary),
            translator: translator
        )
        
        try _test(
            schemaIn: .boolean,
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary),
            translator: translator
        )
        
        try _test(
            schemaIn: .string(allowedValues: ["foo"]),
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary),
            translator: translator
        )
        
        try _test(
            schemaIn: .array(items: .string),
            source: .infer(.primitive),
            repetition: .array,
            schemaOut: .string(contentEncoding: .binary),
            translator: translator
        )
        
        try _test(
            schemaIn: .any(of: .string, .string(allowedValues: ["foo"])),
            source: .infer(.primitive),
            repetition: .single,
            schemaOut: .string(contentEncoding: .binary),
            translator: translator
        )
    }
}
