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
        guard let multipart = try parseMultipartContent(content) else {
            return []
        }
        let parts = multipart.parts
        let multipartBodyTypeName = multipart.typeName

        let partDecls: [Declaration] = try parts.flatMap { part in
            let caseDecl: Declaration
            let associatedDecls: [Declaration]
            switch part {
            case .documentedTyped(let documentedPart):
                caseDecl = .enumCase(
                    name: swiftSafeName(for: documentedPart.originalName),
                    kind: .nameWithAssociatedValues([
                        .init(type: .init(part.wrapperTypeUsage))
                    ])
                )
                let decl = try translateMultipartPartContentInTypes(
                    typeName: documentedPart.typeName,
                    headers: documentedPart.headers,
                    contentType: documentedPart.partInfo.contentType,
                    schema: documentedPart.schema
                )
                associatedDecls = [decl]
            default:
                // TODO: Handle other cases too
                associatedDecls = []
                fatalError("Unsupported")
            }
            return associatedDecls + [caseDecl]
        }
        
        let additionalPropertiesStrategy = multipart.additionalPropertiesStrategy
        let additionalPropertiesDecls: [Declaration] = translateMultipartAdditionalPropertiesCase(additionalPropertiesStrategy)
        
        let enumDescription = EnumDescription(
            isFrozen: true,
            accessModifier: config.access,
            name: multipartBodyTypeName.shortSwiftName,
            conformances: Constants.Operation.Body.conformances,
            members: partDecls + additionalPropertiesDecls
        )
        let comment: Comment? = multipartBodyTypeName.docCommentWithUserDescription(nil)
        return [.commentable(comment, .enum(enumDescription))]
    }
    
    func translateMultipartPartContentInTypes(
        typeName: TypeName,
        headers headerMap: OpenAPI.Header.Map?,
        contentType: ContentType,
        schema: JSONSchema
    ) throws -> Declaration {
        let headersTypeName = typeName.appending(
            swiftComponent: Constants.Operation.Output.Payload.Headers.typeName,
            jsonComponent: "headers"
        )
        let headers = try typedResponseHeaders(from: headerMap, inParent: headersTypeName)
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
        
        let bodyTypeUsage = try typeAssigner.typeUsage(
            forObjectPropertyNamed: Constants.Operation.Body.variableName,
            withSchema: schema.requiredSchemaObject(),
            components: components,
            inParent: typeName.appending(
                swiftComponent: nil,
                jsonComponent: "content"
            )
        )
        let associatedDeclarations: [Declaration]
        if TypeMatcher.isInlinable(schema) {
            associatedDeclarations = try translateSchema(
                typeName: bodyTypeUsage.typeName,
                schema: schema,
                overrides: .none
            )
        } else {
            associatedDeclarations = []
        }
        let bodyProperty = PropertyBlueprint(
            comment: nil,
            originalName: Constants.Operation.Body.variableName,
            typeUsage: bodyTypeUsage,
            associatedDeclarations: associatedDeclarations,
            asSwiftSafeName: swiftSafeName
        )
        
        let structDecl = translateStructBlueprint(
            .init(
                comment: nil,
                access: config.access,
                typeName: typeName,
                conformances: Constants.Operation.Output.Payload.conformances,
                properties: [headersProperty, bodyProperty].compactMap { $0 }
            )
        )
        return .commentable(
            typeName.docCommentWithUserDescription(nil),
            structDecl
        )
    }
}

extension FileTranslator {
    func translateSerializerExtraArguments(_ content: TypedSchemaContent) throws -> [FunctionArgumentDescription] {
        guard let multipart = try parseMultipartContent(content) else {
            return []
        }
        
        let requirements = multipart.requirements
        func sortedStringSetLiteral(_ set: Set<String>) -> Expression {
            .literal(.array(set.sorted().map { .literal($0) }))
        }
        let requirementsArgs: [FunctionArgumentDescription] = [
            .init(
                label: "allowsUnknownParts",
                expression: .literal(.bool(requirements.allowsUnknownParts))
            ),
            .init(
                label: "requiredExactlyOncePartNames",
                expression: sortedStringSetLiteral(requirements.requiredExactlyOncePartNames)
            ),
            .init(
                label: "requiredAtLeastOncePartNames",
                expression: sortedStringSetLiteral(requirements.requiredAtLeastOncePartNames)
            ),
            .init(
                label: "atMostOncePartNames",
                expression: sortedStringSetLiteral(requirements.atMostOncePartNames)
            ),
            .init(
                label: "zeroOrMoreTimesPartNames",
                expression: sortedStringSetLiteral(requirements.zeroOrMoreTimesPartNames)
            ),
        ]
        
        // TODO: Add multipart arguments to the `setRequiredRequestBodyAsMultipart` method here.
        // TODO: Do this in a separate method, at least, or even better, a separate file.
        // requirements args (5), encoding closure (1)
        return requirementsArgs + []
    }
}

//extension ClientFileTranslator {
//    func translateMultipartRequestBodyInClient(
//        _ requestBody: TypedRequestBody,
//        requestVariableName: String,
//        bodyVariableName: String,
//        inputVariableName: String
//    ) throws -> Expression {
//    }
//}

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

