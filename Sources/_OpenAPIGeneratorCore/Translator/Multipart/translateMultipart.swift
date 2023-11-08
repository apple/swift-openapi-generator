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

extension TypesFileTranslator {
    
    // TODO: Document
    func translateMultipartBody(_ content: TypedSchemaContent) throws -> [Declaration] {
        let schemaContent = content.content
        precondition(schemaContent.contentType.isMultipart, "Unexpected content type passed to translateMultipartBody")
        
        let topLevelSchema = schemaContent.schema ?? .b(.fragment)
        print(topLevelSchema)
        
        // TODO: Add isSchemaSupportedForMultipart, where we check object-ish top level.
        // But make that easily matrix testable, so not here
        
        // TODO: Then, add (to TypeMatcher?) something that returns the "requirements" for each
        // property, i.e. optionalArray, optionalSingle, requiredSingle, requiredArrayAtLeastOne
        // But make that easily matrix testable, so not here
        
        // TODO: For each property, also derive the contentType, first by inspecting the encoding
        // and contentEncoding in the schema (get the precedence correct!), then by falling back
        // to the rules described in OpenAPI.
        
        // TODO: Handle additionalProperties (nil, true, false, schema).
        
        // TODO: Create a "MultipartCasePayloadKind" enum of: staticallyNamed, dynamicallyNamed, raw
        // TODO: Create a "MultipartCaseKind" enum of: name+staticallyNamed, undocumented+raw, other+dynamicallyNamed, other+raw
        
        return []
    }
}
