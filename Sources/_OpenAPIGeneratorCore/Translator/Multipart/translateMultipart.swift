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
                return associatedDecls + [caseDecl]
            default:
                // Handled in translateMultipartAdditionalPropertiesCase.
                return []
            }
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
    
    // TODO: Make this take the MultipartContent type
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
        
        // TODO: Factor this out and reuse
        
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

extension ClientFileTranslator {
    func translateMultipartSerializerExtraArgumentsInClient(_ content: TypedSchemaContent) throws -> [FunctionArgumentDescription] {
        try translateMultipartSerializerExtraArguments(
            content,
            setBodyMethodPrefix: "setRequiredRequestBody"
        )
    }
    
    func translateMultipartDeserializerExtraArgumentsInClient(_ content: TypedSchemaContent) throws -> [FunctionArgumentDescription] {
        try translateMultipartDeserializerExtraArguments(
            content,
            getBodyMethodPrefix: "getResponseBody"
        )
    }
}

extension ServerFileTranslator {
    func translateMultipartDeserializerExtraArgumentsInServer(_ content: TypedSchemaContent) throws -> [FunctionArgumentDescription] {
        try translateMultipartDeserializerExtraArguments(
            content,
            getBodyMethodPrefix: "getRequiredRequestBody"
        )
    }
    
    func translateMultipartSerializerExtraArgumentsInServer(_ content: TypedSchemaContent) throws -> [FunctionArgumentDescription] {
        try translateMultipartSerializerExtraArguments(
            content,
            setBodyMethodPrefix: "setResponseBody"
        )
    }
}

extension FileTranslator {
    func translateMultipartRequirementsExtraArguments(_ requirements: MultipartRequirements) throws -> [FunctionArgumentDescription] {
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
        return requirementsArgs
    }
    
    func translateMultipartDeserializerExtraArguments(
        _ content: TypedSchemaContent,
        getBodyMethodPrefix: String
    ) throws -> [FunctionArgumentDescription] {
        guard let multipart = try parseMultipartContent(content) else {
            return []
        }
        let boundaryArg: FunctionArgumentDescription = .init(
            label: "boundary",
            expression: .identifierPattern("contentType").dot("requiredBoundary").call([])
        )
        let requirementsArgs = try translateMultipartRequirementsExtraArguments(multipart.requirements)
        let decoding: FunctionArgumentDescription = .init(
            label: "decoding",
            expression: .closureInvocation(
                argumentNames: ["part"],
                body: try translateMultipartDecodingClosure(multipart, getBodyMethodPrefix: getBodyMethodPrefix)
            )
        )
        return [boundaryArg] + requirementsArgs + [decoding]
    }
    
    func translateMultipartDecodingClosure(
        _ multipart: MultipartContent,
        getBodyMethodPrefix: String
    ) throws -> [CodeBlock] {
        let cases: [SwitchCaseDescription] = try multipart.parts.compactMap { (part) -> SwitchCaseDescription? in
            switch part {
            case .documentedTyped(let part):
                let originalName = part.originalName
                let identifier = swiftSafeName(for: originalName)
                let contentType = part.partInfo.contentType
                let contentTypeHeaderValue = contentType.headerValueForValidation
                let codingStrategy = contentType.codingStrategy
                let schema = part.schema
                let partTypeName = part.typeName
                
                guard try validateSchemaIsSupported(
                    schema,
                    foundIn: partTypeName.description
                ) else {
                    return nil
                }
                let contentTypeUsage = try typeAssigner.typeUsage(
                    forObjectPropertyNamed: Constants.Operation.Body.variableName,
                    withSchema: schema.requiredSchemaObject(),
                    components: components,
                    inParent: partTypeName.appending(
                        swiftComponent: nil,
                        jsonComponent: "content"
                    )
                )

                let verifyContentTypeExpr: Expression = .try(
                    .identifierPattern("converter").dot("verifyContentTypeIfPresent").call([
                        .init(label: "in", expression: .identifierPattern("headerFields")),
                        .init(label: "matches", expression: .literal(contentTypeHeaderValue)),
                    ])
                )
                
                let headersTypeName = part.typeName.appending(
                    swiftComponent: Constants.Operation.Output.Payload.Headers.typeName,
                    jsonComponent: "headers"
                )
                let headers = try typedResponseHeaders(from: part.headers, inParent: headersTypeName)
                
                let headersDecls: [Declaration]
                if !headers.isEmpty {
                    let headerExprs: [FunctionArgumentDescription] = try headers.map { header in
                        try translateMultipartIncomingHeader(header)
                    }
                    let headersDecl: Declaration = .variable(
                        kind: .let,
                        left: "headers",
                        type: .init(headersTypeName),
                        right: .dot("init").call(headerExprs)
                    )
                    headersDecls = [headersDecl]
                } else {
                    headersDecls = []
                }

                let transformExpr: Expression = .closureInvocation(
                    body: [.expression(.identifierPattern("$0"))]
                )
                let converterExpr: Expression = .identifierPattern("converter")
                    .dot("\(getBodyMethodPrefix)As\(codingStrategy.runtimeName)")
                    .call([
                        .init(label: nil, expression: .identifierType(contentTypeUsage.withOptional(false)).dot("self")),
                        .init(label: "from", expression: .identifierPattern("part").dot("body")),
                        .init(label: "transforming", expression: transformExpr),
                    ])
                let bodyExpr: Expression
                switch codingStrategy {
                case .json, .uri, .urlEncodedForm:
                    // Buffering.
                    bodyExpr = .try(.await(converterExpr))
                case .binary, .multipart:
                    // Streaming.
                    bodyExpr = .try(converterExpr)
                }
                let bodyDecl: Declaration = .variable(
                    kind: .let,
                    left: "body",
                    right: bodyExpr
                )

                let headersVarArgs: [FunctionArgumentDescription]
                if !headers.isEmpty {
                    headersVarArgs = [
                        .init(label: "headers", expression: .identifierPattern("headers"))
                    ]
                } else {
                    headersVarArgs = []
                }
                let payloadInitExpr: Expression = .dot("init").call(headersVarArgs + [
                    .init(label: "body", expression: .identifierPattern("body"))
                ])
                let returnExpr: Expression = .return(
                    .dot(identifier).call([
                        .init(
                            expression: .dot("init").call([
                                .init(label: "payload", expression: payloadInitExpr),
                                .init(label: "filename", expression: .identifierPattern("filename")),
                            ])
                        )
                    ])
                )
                return .init(
                    kind: .case(.literal(originalName)),
                    body: headersDecls.map { .declaration($0) } + [
                        .expression(verifyContentTypeExpr),
                        .declaration(bodyDecl),
                        .expression(returnExpr)
                    ]
                )
            case .undocumented:
                return .init(
                    kind: .default,
                    body: [
                        .expression(.return(.dot("undocumented").call([
                            .init(expression: .identifierPattern("part"))
                        ])))
                    ]
                )
            case .otherRaw:
                return .init(
                    kind: .default,
                    body: [
                        .expression(.return(.dot("other").call([
                            .init(expression: .identifierPattern("part"))
                        ])))
                    ]
                )
            case .otherDynamicallyNamed:
                return nil
            }
        }
        let hasAtLeastOneTypedPart = multipart.parts.contains { part in
            switch part {
            case .documentedTyped, .otherDynamicallyNamed:
                return true
            case .otherRaw, .undocumented:
                return false
            }
        }
        return [
            .declaration(
                .variable(
                    kind: .let,
                    left: "headerFields",
                    right: .identifierPattern("part").dot("headerFields")
                )
            ),
            .declaration(
                .variable(
                    kind: .let,
                    left: .tuple([.identifierPattern("name"), .identifierPattern(hasAtLeastOneTypedPart ? "filename" : "_")]),
                    right: .try(
                        .identifierPattern("converter")
                        .dot("extractContentDispositionNameAndFilename")
                        .call([
                            .init(label: "in", expression: .identifierPattern("headerFields"))
                        ])
                    )
                )
            ),
            .expression(
                .switch(
                    switchedExpression: .identifierPattern("name"),
                    cases: cases
                )
            )
        ]
    }
    
    func translateMultipartSerializerExtraArguments(
        _ content: TypedSchemaContent,
        setBodyMethodPrefix: String
    ) throws -> [FunctionArgumentDescription] {
        guard let multipart = try parseMultipartContent(content) else {
            return []
        }
        let requirementsArgs = try translateMultipartRequirementsExtraArguments(multipart.requirements)
        let encoding: FunctionArgumentDescription = .init(
            label: "encoding",
            expression: .closureInvocation(
                argumentNames: ["part"],
                body: try translateMultipartEncodingClosure(multipart, setBodyMethodPrefix: setBodyMethodPrefix)
            )
        )
        return requirementsArgs + [encoding]
    }
    
    func translateMultipartEncodingClosure(
        _ multipart: MultipartContent,
        setBodyMethodPrefix: String
    ) throws -> [CodeBlock] {
        let cases: [SwitchCaseDescription] = try multipart.parts.compactMap { part in
            switch part {
            case .documentedTyped(let part):
                let originalName = part.originalName
                let identifier = swiftSafeName(for: originalName)
                let contentType = part.partInfo.contentType
                let contentTypeHeaderValue = contentType.headerValueForSending
                let headersDecl: Declaration = .variable(
                    kind: .var,
                    left: "headerFields",
                    type: .init(.httpFields),
                    right: .dot("init").call([])
                )
                
                let headersTypeName = part.typeName.appending(
                    swiftComponent: Constants.Operation.Output.Payload.Headers.typeName,
                    jsonComponent: "headers"
                )
                let headers = try typedResponseHeaders(from: part.headers, inParent: headersTypeName)
                let headerExprs: [Expression] = try headers.map { header in
                    try translateMultipartOutgoingHeader(header)
                }
                
                let valueDecl: Declaration = .variable(
                    kind: .let,
                    left: "value",
                    right: .identifierPattern("wrapped").dot("payload")
                )
                let bodyDecl: Declaration = .variable(
                    kind: .let,
                    left: "body",
                    right: .try(
                        .identifierPattern("converter")
                        .dot(
                            "\(setBodyMethodPrefix)As\(contentType.codingStrategy.runtimeName)"
                        )
                        .call([
                            .init(label: nil, expression: .identifierPattern("value").dot("body")),
                            .init(
                                label: "headerFields",
                                expression: .inOut(.identifierPattern("headerFields"))
                            ), .init(label: "contentType", expression: .literal(contentTypeHeaderValue)),
                        ])
                    )
                )
                let returnExpr: Expression = .return(
                    .dot("init").call([
                        .init(label: "name", expression: .literal(originalName)),
                        .init(label: "filename", expression: .identifierPattern("wrapped").dot("filename")),
                        .init(label: "headerFields", expression: .identifierPattern("headerFields")),
                        .init(label: "body", expression: .identifierPattern("body")),
                    ])
                )
                return .init(
                    kind: .case(.dot(identifier), ["wrapped"]),
                    body: [
                        .declaration(headersDecl),
                        .declaration(valueDecl),
                    ] +
                    headerExprs.map { .expression($0) } +
                    [
                        .declaration(bodyDecl),
                        .expression(returnExpr)
                    ]
                )
            case .undocumented:
                return .init(
                    kind: .case(.dot("undocumented"), ["value"]),
                    body: [
                        .expression(.return(.identifierPattern("value")))
                    ]
                )
            case .otherRaw:
                return .init(
                    kind: .case(.dot("other"), ["value"]),
                    body: [
                        .expression(.return(.identifierPattern("value")))
                    ]
                )
            case .otherDynamicallyNamed:
                return nil
            }
        }
        return [
            .expression(
                .switch(
                    switchedExpression: .identifierPattern("part"),
                    cases: cases
                )
            )
        ]
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

