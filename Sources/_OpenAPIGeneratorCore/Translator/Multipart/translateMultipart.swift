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

    /// Returns declarations representing the provided multipart content.
    /// - Parameter content: The multipart content.
    /// - Returns: A list of declarations, or empty if not valid multipart content.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartBody(_ content: TypedSchemaContent) throws -> [Declaration] {
        guard let multipart = try parseMultipartContent(content) else { return [] }
        let decl = try translateMultipartBody(multipart)
        return [decl]
    }

    /// Returns a declaration of a multipart part's associated type, containing headers (if defined) and body.
    /// - Parameters:
    ///   - typeName: The type name of the part's type.
    ///   - headerMap: The headers for the part.
    ///   - contentType: The content type of the part.
    ///   - schema: The schema of the part's body.
    /// - Returns: A declaration of the type containing headers and body.
    /// - Throws: An error if the schema is malformed or a reference cannot be followed.
    func translateMultipartPartContent(
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
                context: context
            )
        } else {
            headersProperty = nil
        }
        let bodyTypeUsage = try typeAssigner.typeUsage(
            forObjectPropertyNamed: Constants.Operation.Body.variableName,
            withSchema: schema.requiredSchemaObject(),
            components: components,
            inParent: typeName.appending(swiftComponent: nil, jsonComponent: "content")
        )
        let associatedDeclarations: [Declaration]
        if typeMatcher.isInlinable(schema) {
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
            context: context
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
        return .commentable(typeName.docCommentWithUserDescription(nil), structDecl)
    }

    /// Returns the associated declarations of a dynamically named part.
    /// - Parameters:
    ///   - typeName: The type name of the part.
    ///   - contentType: The cotent type of the part.
    ///   - schema: The schema of the part.
    /// - Returns: The associated declarations, or empty if the type is referenced.
    /// - Throws: An error if the schema is malformed or a reference cannot be followed.
    func translateMultipartPartContentAdditionalPropertiesWithSchemaAssociatedDeclarations(
        typeName: TypeName,
        contentType: ContentType,
        schema: JSONSchema
    ) throws -> [Declaration] {
        let associatedDeclarations: [Declaration]
        if typeMatcher.isInlinable(schema) {
            associatedDeclarations = try translateSchema(typeName: typeName, schema: schema, overrides: .none)
        } else {
            associatedDeclarations = []
        }
        return associatedDeclarations
    }

    /// Returns the declaration for the provided root multipart content.
    /// - Parameter multipart: The multipart content.
    /// - Returns: The declaration of the multipart container enum type.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartBody(_ multipart: MultipartContent) throws -> Declaration {
        let parts = multipart.parts
        let multipartBodyTypeName = multipart.typeName

        let partDecls: [Declaration] = try parts.flatMap { part -> [Declaration] in
            switch part {
            case .documentedTyped(let documentedPart):
                let caseDecl: Declaration = .enumCase(
                    name: context.safeNameGenerator.swiftMemberName(for: documentedPart.originalName),
                    kind: .nameWithAssociatedValues([.init(type: .init(part.wrapperTypeUsage))])
                )
                let decl = try translateMultipartPartContent(
                    typeName: documentedPart.typeName,
                    headers: documentedPart.headers,
                    contentType: documentedPart.partInfo.contentType,
                    schema: documentedPart.schema
                )
                return [decl, caseDecl]
            case .otherDynamicallyNamed(let dynamicallyNamedPart):
                let caseDecl: Declaration = .enumCase(
                    name: Constants.AdditionalProperties.variableName,
                    kind: .nameWithAssociatedValues([.init(type: .init(part.wrapperTypeUsage))])
                )
                let associatedDecls =
                    try translateMultipartPartContentAdditionalPropertiesWithSchemaAssociatedDeclarations(
                        typeName: dynamicallyNamedPart.typeName,
                        contentType: dynamicallyNamedPart.partInfo.contentType,
                        schema: dynamicallyNamedPart.schema
                    )
                return associatedDecls + [caseDecl]
            case .otherRaw:
                return [
                    .enumCase(name: "other", kind: .nameWithAssociatedValues([.init(type: .init(.multipartRawPart))]))
                ]
            case .undocumented:
                return [
                    .enumCase(
                        name: "undocumented",
                        kind: .nameWithAssociatedValues([.init(type: .init(.multipartRawPart))])
                    )
                ]
            }
        }
        let enumDescription = EnumDescription(
            isFrozen: true,
            accessModifier: config.access,
            name: multipartBodyTypeName.shortSwiftName,
            conformances: Constants.Operation.Body.conformances,
            members: partDecls
        )
        let comment: Comment? = multipartBodyTypeName.docCommentWithUserDescription(nil)
        return .commentable(comment, .enum(enumDescription))
    }

    /// Returns the declaration for the provided root multipart content.
    /// - Parameters:
    ///   - typeName: The type name of the body.
    ///   - schema: The root schema of the body.
    /// - Returns: The declaration of the multipart container enum type.
    /// - Throws: An error if the schema is malformed or a reference cannot be followed.
    func translateMultipartBody(typeName: TypeName, schema: JSONSchema) throws -> [Declaration] {
        guard let multipart = try parseMultipartContent(typeName: typeName, schema: .b(schema), encoding: nil) else {
            return []
        }
        let decl = try translateMultipartBody(multipart)
        return [decl]
    }
}

extension ClientFileTranslator {

    /// Returns the extra function arguments used for multipart serializers (request) in the client code.
    /// - Parameter content: The multipart content.
    /// - Returns: The extra function arguments.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartSerializerExtraArgumentsInClient(_ content: TypedSchemaContent) throws
        -> [FunctionArgumentDescription]
    { try translateMultipartSerializerExtraArguments(content, setBodyMethodPrefix: "setRequiredRequestBody") }

    /// Returns the extra function arguments used for multipart deserializers (response) in the client code.
    /// - Parameter content: The multipart content.
    /// - Returns: The extra function arguments.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartDeserializerExtraArgumentsInClient(_ content: TypedSchemaContent) throws
        -> [FunctionArgumentDescription]
    { try translateMultipartDeserializerExtraArguments(content, getBodyMethodPrefix: "getResponseBody") }
}

extension ServerFileTranslator {

    /// Returns the extra function arguments used for multipart deserializers (request) in the server code.
    /// - Parameter content: The multipart content.
    /// - Returns: The extra function arguments.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartDeserializerExtraArgumentsInServer(_ content: TypedSchemaContent) throws
        -> [FunctionArgumentDescription]
    { try translateMultipartDeserializerExtraArguments(content, getBodyMethodPrefix: "getRequiredRequestBody") }

    /// Returns the extra function arguments used for multipart serializers (response) in the server code.
    /// - Parameter content: The multipart content.
    /// - Returns: The extra function arguments.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartSerializerExtraArgumentsInServer(_ content: TypedSchemaContent) throws
        -> [FunctionArgumentDescription]
    { try translateMultipartSerializerExtraArguments(content, setBodyMethodPrefix: "setResponseBody") }
}

extension FileTranslator {

    /// Returns the requirements-related extra function arguments used for multipart serializers and deserializers.
    /// - Parameter requirements: The requirements to generate arguments for.
    /// - Returns: The list of arguments.
    func translateMultipartRequirementsExtraArguments(_ requirements: MultipartRequirements)
        -> [FunctionArgumentDescription]
    {
        func sortedStringSetLiteral(_ set: Set<String>) -> Expression {
            .literal(.array(set.sorted().map { .literal($0) }))
        }
        let requirementsArgs: [FunctionArgumentDescription] = [
            .init(label: "allowsUnknownParts", expression: .literal(.bool(requirements.allowsUnknownParts))),
            .init(
                label: "requiredExactlyOncePartNames",
                expression: sortedStringSetLiteral(requirements.requiredExactlyOncePartNames)
            ),
            .init(
                label: "requiredAtLeastOncePartNames",
                expression: sortedStringSetLiteral(requirements.requiredAtLeastOncePartNames)
            ),
            .init(label: "atMostOncePartNames", expression: sortedStringSetLiteral(requirements.atMostOncePartNames)),
            .init(
                label: "zeroOrMoreTimesPartNames",
                expression: sortedStringSetLiteral(requirements.zeroOrMoreTimesPartNames)
            ),
        ]
        return requirementsArgs
    }

    /// Returns the extra function arguments used for multipart deserializers.
    /// - Parameters:
    ///   - content: The multipart content.
    ///   - getBodyMethodPrefix: The string prefix of the "get body" methods.
    /// - Returns: The extra function arguments.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartDeserializerExtraArguments(_ content: TypedSchemaContent, getBodyMethodPrefix: String) throws
        -> [FunctionArgumentDescription]
    {
        guard let multipart = try parseMultipartContent(content) else { return [] }
        let boundaryArg: FunctionArgumentDescription = .init(
            label: "boundary",
            expression: .identifierPattern("contentType").dot("requiredBoundary").call([])
        )
        let requirementsArgs = translateMultipartRequirementsExtraArguments(multipart.requirements)
        let decoding: FunctionArgumentDescription = .init(
            label: "decoding",
            expression: .closureInvocation(
                argumentNames: ["part"],
                body: try translateMultipartDecodingClosure(multipart, getBodyMethodPrefix: getBodyMethodPrefix)
            )
        )
        return [boundaryArg] + requirementsArgs + [decoding]
    }

    /// Returns the description of the switch case for the provided individual multipart part.
    /// - Parameters:
    ///   - caseName: The name of the case.
    ///   - caseKind: The kind of the case.
    ///   - isDynamicallyNamed: A Boolean value indicating whether the part is dynamically named (in other words, if
    ///     this is using `additionalProperties: <SCHEMA>`.
    ///   - isPayloadBodyTypeNested: A Boolean value indicating whether the payload body type is nested. If `false`,
    ///     then the body type is assumed to be the part's type.
    ///   - getBodyMethodPrefix: The string prefix of the "get body" methods.
    ///   - contentType: The content type of the part.
    ///   - partTypeName: The part's type name.
    ///   - schema: The schema of the part.
    ///   - payloadExpr: The expression of the payload in the corresponding wrapper type.
    ///   - headerDecls: A list of declarations of the part headers, can be empty.
    ///   - headersVarArgs: A list of arguments for headers on the part's type, can be empty.
    /// - Returns: The switch case description, or nil if not valid or supported schema.
    /// - Throws: An error if the schema is malformed or a reference cannot be followed.
    func translateMultipartDecodingClosureTypedPart(
        caseName: String,
        caseKind: SwitchCaseKind,
        isDynamicallyNamed: Bool,
        isPayloadBodyTypeNested: Bool,
        getBodyMethodPrefix: String,
        contentType: ContentType,
        partTypeName: TypeName,
        schema: JSONSchema,
        payloadExpr: Expression,
        headerDecls: [Declaration],
        headersVarArgs: [FunctionArgumentDescription]
    ) throws -> SwitchCaseDescription? {
        let contentTypeHeaderValue = contentType.headerValueForValidation
        let codingStrategy = contentType.codingStrategy
        guard try validateSchemaIsSupported(schema, foundIn: partTypeName.description) else { return nil }
        let contentTypeUsage: TypeUsage
        if isPayloadBodyTypeNested {
            contentTypeUsage = try typeAssigner.typeUsage(
                forObjectPropertyNamed: Constants.Operation.Body.variableName,
                withSchema: schema.requiredSchemaObject(),
                components: components,
                inParent: partTypeName.appending(swiftComponent: nil, jsonComponent: "content")
            )
        } else {
            contentTypeUsage = partTypeName.asUsage
        }

        let verifyContentTypeExpr: Expression = .try(
            .identifierPattern("converter").dot("verifyContentTypeIfPresent")
                .call([
                    .init(label: "in", expression: .identifierPattern("headerFields")),
                    .init(label: "matches", expression: .literal(contentTypeHeaderValue)),
                ])
        )
        let transformExpr: Expression = .closureInvocation(body: [.expression(.identifierPattern("$0"))])
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
        let bodyDecl: Declaration = .variable(kind: .let, left: "body", right: bodyExpr)

        let extraNameArgs: [FunctionArgumentDescription]
        if isDynamicallyNamed {
            extraNameArgs = [.init(label: "name", expression: .identifierPattern("name"))]
        } else {
            extraNameArgs = []
        }
        let returnExpr: Expression = .return(
            .dot(caseName)
                .call([
                    .init(
                        expression: .dot("init")
                            .call(
                                [
                                    .init(label: "payload", expression: payloadExpr),
                                    .init(label: "filename", expression: .identifierPattern("filename")),
                                ] + extraNameArgs
                            )
                    )
                ])
        )
        return .init(
            kind: caseKind,
            body: headerDecls.map { .declaration($0) } + [
                .expression(verifyContentTypeExpr), .declaration(bodyDecl), .expression(returnExpr),
            ]
        )
    }

    /// Returns the code blocks representing the body of the multipart deserializer's decoding closure, parsing the
    /// raw parts into typed parts.
    /// - Parameters:
    ///   - multipart: The multipart content.
    ///   - getBodyMethodPrefix: The string prefix of the "get body" methods.
    /// - Returns: The body code blocks of the decoding closure.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartDecodingClosure(_ multipart: MultipartContent, getBodyMethodPrefix: String) throws
        -> [CodeBlock]
    {
        var cases: [SwitchCaseDescription] = try multipart.parts.compactMap { (part) -> SwitchCaseDescription? in
            switch part {
            case .documentedTyped(let part):
                let originalName = part.originalName
                let identifier = context.safeNameGenerator.swiftMemberName(for: originalName)
                let contentType = part.partInfo.contentType
                let partTypeName = part.typeName
                let schema = part.schema
                let headersTypeName = part.typeName.appending(
                    swiftComponent: Constants.Operation.Output.Payload.Headers.typeName,
                    jsonComponent: "headers"
                )
                let headers = try typedResponseHeaders(from: part.headers, inParent: headersTypeName)
                let headerDecls: [Declaration]
                let headersVarArgs: [FunctionArgumentDescription]
                if !headers.isEmpty {
                    let headerExprs: [FunctionArgumentDescription] = headers.map { header in
                        translateMultipartIncomingHeader(header)
                    }
                    let headersDecl: Declaration = .variable(
                        kind: .let,
                        left: "headers",
                        type: .init(headersTypeName),
                        right: .dot("init").call(headerExprs)
                    )
                    headerDecls = [headersDecl]
                    headersVarArgs = [.init(label: "headers", expression: .identifierPattern("headers"))]
                } else {
                    headerDecls = []
                    headersVarArgs = []
                }
                let payloadExpr: Expression = .dot("init")
                    .call(headersVarArgs + [.init(label: "body", expression: .identifierPattern("body"))])
                return try translateMultipartDecodingClosureTypedPart(
                    caseName: identifier,
                    caseKind: .case(.literal(originalName)),
                    isDynamicallyNamed: false,
                    isPayloadBodyTypeNested: true,
                    getBodyMethodPrefix: getBodyMethodPrefix,
                    contentType: contentType,
                    partTypeName: partTypeName,
                    schema: schema,
                    payloadExpr: payloadExpr,
                    headerDecls: headerDecls,
                    headersVarArgs: headersVarArgs
                )
            case .otherDynamicallyNamed(let part):
                let contentType = part.partInfo.contentType
                let partTypeName = part.typeName
                let schema = part.schema
                let payloadExpr: Expression = .identifierPattern("body")
                return try translateMultipartDecodingClosureTypedPart(
                    caseName: Constants.AdditionalProperties.variableName,
                    caseKind: .default,
                    isDynamicallyNamed: true,
                    isPayloadBodyTypeNested: false,
                    getBodyMethodPrefix: getBodyMethodPrefix,
                    contentType: contentType,
                    partTypeName: partTypeName,
                    schema: schema,
                    payloadExpr: payloadExpr,
                    headerDecls: [],
                    headersVarArgs: []
                )
            case .undocumented:
                return .init(
                    kind: .default,
                    body: [
                        .expression(.return(.dot("undocumented").call([.init(expression: .identifierPattern("part"))])))
                    ]
                )
            case .otherRaw:
                return .init(
                    kind: .default,
                    body: [.expression(.return(.dot("other").call([.init(expression: .identifierPattern("part"))])))]
                )
            }
        }
        if multipart.additionalPropertiesStrategy == .disallowed {
            cases.append(
                .init(
                    kind: .default,
                    body: [
                        .expression(
                            .identifierPattern("preconditionFailure")
                                .call([
                                    .init(
                                        expression: .literal("Unknown part should be rejected by multipart validation.")
                                    )
                                ])
                        )
                    ]
                )
            )
        }
        let hasAtLeastOneTypedPart = multipart.parts.contains { part in
            switch part {
            case .documentedTyped, .otherDynamicallyNamed: return true
            case .otherRaw, .undocumented: return false
            }
        }
        return [
            .declaration(
                .variable(kind: .let, left: "headerFields", right: .identifierPattern("part").dot("headerFields"))
            ),
            .declaration(
                .variable(
                    kind: .let,
                    left: .tuple([
                        .identifierPattern("name"), .identifierPattern(hasAtLeastOneTypedPart ? "filename" : "_"),
                    ]),
                    right: .try(
                        .identifierPattern("converter").dot("extractContentDispositionNameAndFilename")
                            .call([.init(label: "in", expression: .identifierPattern("headerFields"))])
                    )
                )
            ), .expression(.switch(switchedExpression: .identifierPattern("name"), cases: cases)),
        ]
    }

    /// Returns the extra function arguments used for multipart serializers.
    /// - Parameters:
    ///   - content: The multipart content.
    ///   - setBodyMethodPrefix: The string prefix of the "set body" methods.
    /// - Returns: The extra function arguments.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartSerializerExtraArguments(_ content: TypedSchemaContent, setBodyMethodPrefix: String) throws
        -> [FunctionArgumentDescription]
    {
        guard let multipart = try parseMultipartContent(content) else { return [] }
        let requirementsArgs = translateMultipartRequirementsExtraArguments(multipart.requirements)
        let encoding: FunctionArgumentDescription = .init(
            label: "encoding",
            expression: .closureInvocation(
                argumentNames: ["part"],
                body: try translateMultipartEncodingClosure(multipart, setBodyMethodPrefix: setBodyMethodPrefix)
            )
        )
        return requirementsArgs + [encoding]
    }

    /// Returns the description of the switch case for the provided individual multipart part.
    /// - Parameters:
    ///   - caseName: The name of the case.
    ///   - nameExpr: The expression for the part's name.
    ///   - bodyExpr: The expression for the part's body.
    ///   - setBodyMethodPrefix: The string prefix of the "set body" methods.
    ///   - contentType: The content type of the part.
    ///   - headerExprs: A list of expressions of the part headers, can be empty.
    /// - Returns: The switch case description.
    func translateMultipartEncodingClosureTypedPart(
        caseName: String,
        nameExpr: Expression,
        bodyExpr: Expression,
        setBodyMethodPrefix: String,
        contentType: ContentType,
        headerExprs: [Expression]
    ) -> SwitchCaseDescription {
        let contentTypeHeaderValue = contentType.headerValueForSending
        let headersDecl: Declaration = .variable(
            kind: .var,
            left: "headerFields",
            type: .init(.httpFields),
            right: .dot("init").call([])
        )
        let valueDecl: Declaration = .variable(
            kind: .let,
            left: "value",
            right: .identifierPattern("wrapped").dot("payload")
        )
        let bodyDecl: Declaration = .variable(
            kind: .let,
            left: "body",
            right: .try(
                .identifierPattern("converter").dot("\(setBodyMethodPrefix)As\(contentType.codingStrategy.runtimeName)")
                    .call([
                        .init(label: nil, expression: bodyExpr),
                        .init(label: "headerFields", expression: .inOut(.identifierPattern("headerFields"))),
                        .init(label: "contentType", expression: .literal(contentTypeHeaderValue)),
                    ])
            )
        )
        let returnExpr: Expression = .return(
            .dot("init")
                .call([
                    .init(label: "name", expression: nameExpr),
                    .init(label: "filename", expression: .identifierPattern("wrapped").dot("filename")),
                    .init(label: "headerFields", expression: .identifierPattern("headerFields")),
                    .init(label: "body", expression: .identifierPattern("body")),
                ])
        )
        return .init(
            kind: .case(.dot(caseName), ["wrapped"]),
            body: [.declaration(headersDecl), .declaration(valueDecl)] + headerExprs.map { .expression($0) } + [
                .declaration(bodyDecl), .expression(returnExpr),
            ]
        )
    }

    /// Returns the code blocks representing the body of the multipart serializer's encoding closure, serializing the
    /// typed parts into raw parts.
    /// - Parameters:
    ///   - multipart: The multipart content.
    ///   - setBodyMethodPrefix: The string prefix of the "set body" methods.
    /// - Returns: The body code blocks of the encoding closure.
    /// - Throws: An error if the content is malformed or a reference cannot be followed.
    func translateMultipartEncodingClosure(_ multipart: MultipartContent, setBodyMethodPrefix: String) throws
        -> [CodeBlock]
    {
        let cases: [SwitchCaseDescription] = try multipart.parts.compactMap { part in
            switch part {
            case .documentedTyped(let part):
                let originalName = part.originalName
                let identifier = context.safeNameGenerator.swiftMemberName(for: originalName)
                let contentType = part.partInfo.contentType
                let headersTypeName = part.typeName.appending(
                    swiftComponent: Constants.Operation.Output.Payload.Headers.typeName,
                    jsonComponent: "headers"
                )
                let headers = try typedResponseHeaders(from: part.headers, inParent: headersTypeName)
                let headerExprs: [Expression] = headers.map { header in translateMultipartOutgoingHeader(header) }
                return translateMultipartEncodingClosureTypedPart(
                    caseName: identifier,
                    nameExpr: .literal(originalName),
                    bodyExpr: .identifierPattern("value").dot("body"),
                    setBodyMethodPrefix: setBodyMethodPrefix,
                    contentType: contentType,
                    headerExprs: headerExprs
                )
            case .otherDynamicallyNamed(let part):
                let contentType = part.partInfo.contentType
                return translateMultipartEncodingClosureTypedPart(
                    caseName: Constants.AdditionalProperties.variableName,
                    nameExpr: .identifierPattern("wrapped").dot("name"),
                    bodyExpr: .identifierPattern("value"),
                    setBodyMethodPrefix: setBodyMethodPrefix,
                    contentType: contentType,
                    headerExprs: []
                )
            case .undocumented:
                return .init(
                    kind: .case(.dot("undocumented"), ["value"]),
                    body: [.expression(.return(.identifierPattern("value")))]
                )
            case .otherRaw:
                return .init(
                    kind: .case(.dot("other"), ["value"]),
                    body: [.expression(.return(.identifierPattern("value")))]
                )
            }
        }
        return [.expression(.switch(switchedExpression: .identifierPattern("part"), cases: cases))]
    }
}
