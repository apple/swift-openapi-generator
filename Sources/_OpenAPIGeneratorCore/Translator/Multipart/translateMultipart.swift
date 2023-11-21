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
        let typeUsage = content.typeUsage! /* TODO: remove bang */
        let typeName = typeUsage.typeName
        
        var referenceStack: ReferenceStack = .empty
        guard let topLevelObject = try flattenedTopLevelMultipartObject(topLevelSchema, referenceStack: &referenceStack) else {
            return []
        }
        
        let encoding = schemaContent.encoding
        
        let parts = try topLevelObject.properties.compactMap { (key, value) in
            try parseMultipartContentIfSupported(
                key: key,
                schema: value,
                encoding: encoding?[key],
                parent: typeName
            )
        }
        
        let partDecls: [Declaration] = try parts.flatMap { part in
            let associatedDecls: [Declaration]
            switch part.caseKind {
            case .documentedTyped(let typeName):
                let decl = try translateMultipartPartContentInTypes(
                    headers: part.headers, 
                    contentType: part.contentType,
                    schema: part.schema,
                    parent: typeName
                )
                associatedDecls = [decl]
            default:
                // TODO: Handle other cases too
                associatedDecls = []
            }
            let caseDecl: Declaration = .enumCase(
                name: swiftSafeName(for: part.originalName),
                kind: .nameWithAssociatedValues([
                    .init(type: .init(part.wrapperTypeUsage))
                ])
            )
            return associatedDecls + [caseDecl]
        }
        
        
        // TODO: Check additional properties
        
        let enumDescription = EnumDescription(
            isFrozen: true,
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            conformances: Constants.Operation.Body.conformances,
            members: partDecls
        )
        let comment: Comment? = typeName.docCommentWithUserDescription(nil)
        return [.commentable(comment, .enum(enumDescription))]
    }
    
    func translateMultipartPartContentInTypes(
        headers: [TypedResponseHeader],
        contentType: ContentType,
        schema: JSONSchema,
        parent: TypeName
    ) throws -> Declaration {
        let headersTypeName = parent.appending(
            swiftComponent: Constants.Operation.Output.Payload.Headers.typeName,
            jsonComponent: "headers"
        )
        let headersProperty: PropertyBlueprint?
        if !headers.isEmpty {
            let headerProperties: [PropertyBlueprint] = try headers.map { header in
                try parseResponseHeaderAsProperty(for: header, parent: headersTypeName)
            }
            let headerStructComment: Comment? = headersTypeName.docCommentWithUserDescription(nil)
            let headersStructBlueprint: StructBlueprint = .init(
                comment: headerStructComment,
                access: config.access,
                typeName: headersTypeName,
                conformances: Constants.Operation.Output.Payload.Headers.conformances,
                properties: headerProperties
            )
            let headersStructDecl = translateStructBlueprint(headersStructBlueprint)
            headersProperty = PropertyBlueprint(
                comment: .doc("Received HTTP response headers"),
                originalName: Constants.Operation.Output.Payload.Headers.variableName,
                typeUsage: headersTypeName.asUsage,
                default: headersStructBlueprint.hasEmptyInit ? .emptyInit : nil,
                associatedDeclarations: [headersStructDecl],
                asSwiftSafeName: swiftSafeName
            )
        } else {
            headersProperty = nil
        }
        
        let bodyTypeName = parent.appending(
            swiftComponent: Constants.Operation.Body.typeName,
            jsonComponent: "content"
        )
        
        let propertyType = try typeAssigner.typeUsage(
            forObjectPropertyNamed: Constants.Operation.Body.variableName,
            withSchema: schema,
            components: components,
            inParent: bodyTypeName
        )
        let associatedDeclarations: [Declaration]
        if TypeMatcher.isInlinable(schema) {
            associatedDeclarations = try translateSchema(
                typeName: propertyType.typeName,
                schema: schema,
                overrides: .none
            )
        } else {
            associatedDeclarations = []
        }
        let bodyProperty = PropertyBlueprint(
            comment: nil,
            originalName: Constants.Operation.Body.variableName,
            typeUsage: propertyType,
            associatedDeclarations: associatedDeclarations,
            asSwiftSafeName: swiftSafeName
        )
        
        let structDecl = translateStructBlueprint(
            .init(
                comment: nil,
                access: config.access,
                typeName: parent,
                conformances: Constants.Operation.Output.Payload.conformances,
                properties: [headersProperty, bodyProperty].compactMap { $0 }
            )
        )
        return structDecl
    }
}

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
// TODO: Create a "MultipartCaseKind" enum of: name+staticallyNamed, undocumented+raw, other+dynamicallyNamed, other+raw, disallowed

// TODO: Generate the enum members (inline types and cases)

// TODO: Create some typesafe MultipartContent struct, as we'll need to parse this out
// in more places and use when generating client/server code as well.

// TODO: Support both an inline top level schema and a reference top level schema.

