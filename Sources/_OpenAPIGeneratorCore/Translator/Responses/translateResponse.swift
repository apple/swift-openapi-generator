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

    /// Returns a declaration that defines a Swift type for the response.
    /// - Parameters:
    ///   - typeName: The type name for the response structure.
    ///   - response: The typed response information containing the response headers and body content.
    /// - Returns: A structure declaration representing the response type.
    /// - Throws: An error if there's an issue while generating the response type declaration,
    ///           extracting response headers, or processing the body content.
    func translateResponseInTypes(typeName: TypeName, response: TypedResponse) throws -> Declaration {
        let response = response.response

        let headersTypeName = typeName.appending(
            swiftComponent: Constants.Operation.Output.Payload.Headers.typeName,
            jsonComponent: "headers"
        )
        let headers = try typedResponseHeaders(from: response, inParent: headersTypeName)
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

        let bodyTypeName = typeName.appending(
            swiftComponent: Constants.Operation.Body.typeName,
            jsonComponent: "content"
        )
        let typedContents = try supportedTypedContents(response.content, isRequired: true, inParent: bodyTypeName)

        let bodyProperty: PropertyBlueprint?
        if !typedContents.isEmpty {
            var bodyCases: [Declaration] = []
            for typedContent in typedContents {
                let newBodyCases = try translateResponseBodyContentInTypes(
                    typedContent,
                    bodyTypeName: bodyTypeName,
                    hasMultipleContentTypes: typedContents.count > 1
                )
                bodyCases.append(contentsOf: newBodyCases)
            }
            let hasNoContent: Bool = bodyCases.isEmpty
            let contentEnumDecl: Declaration = .commentable(
                bodyTypeName.docCommentWithUserDescription(nil),
                .enum(
                    isFrozen: true,
                    accessModifier: config.access,
                    name: bodyTypeName.shortSwiftName,
                    conformances: Constants.Operation.Body.conformances,
                    members: bodyCases
                )
            )

            let contentTypeUsage = bodyTypeName.asUsage.withOptional(hasNoContent)
            bodyProperty = PropertyBlueprint(
                comment: .doc("Received HTTP response body"),
                originalName: Constants.Operation.Body.variableName,
                typeUsage: contentTypeUsage,
                default: hasNoContent ? .nil : nil,
                associatedDeclarations: [contentEnumDecl],
                context: context
            )
        } else {
            bodyProperty = nil
        }

        let responseStructDecl = translateStructBlueprint(
            .init(
                comment: nil,
                access: config.access,
                typeName: typeName,
                conformances: Constants.Operation.Output.Payload.conformances,
                properties: [headersProperty, bodyProperty].compactMap { $0 }
            )
        )

        return responseStructDecl
    }

    /// Returns a list of declarations for the specified reusable response
    /// defined under the specified key in the OpenAPI document.
    /// - Parameters:
    ///   - componentKey: The component key used for the reusable response
    ///   in the OpenAPI document.
    ///   - response: The response to declare.
    /// - Returns: A structure declaration.
    /// - Throws: An error if there's an issue while generating the response header type declaration,
    ///           or if there's a problem with extracting response headers or processing the body content.
    func translateResponseHeaderInTypes(componentKey: OpenAPI.ComponentKey, response: TypedResponse) throws
        -> Declaration
    {
        let typeName = typeAssigner.typeName(for: componentKey, of: OpenAPI.Response.self)
        return try translateResponseInTypes(typeName: typeName, response: response)
    }

    /// Returns a list of declarations for the specified content to be generated in the provided body namespace.
    /// - Parameters:
    ///   - typedContent: The content to generated.
    ///   - bodyTypeName: The parent body type name.
    ///   - hasMultipleContentTypes: A Boolean value indicating whether there are more than one content types.
    /// - Returns: A list of declarations.
    /// - Throws: If the translation of underlying schemas fails.
    func translateResponseBodyContentInTypes(
        _ typedContent: TypedSchemaContent,
        bodyTypeName: TypeName,
        hasMultipleContentTypes: Bool
    ) throws -> [Declaration] {
        var bodyCases: [Declaration] = []
        let contentType = typedContent.content.contentType
        let identifier = context.safeNameGenerator.swiftContentTypeName(for: contentType)
        let associatedType = typedContent.resolvedTypeUsage
        let content = typedContent.content
        let schema = content.schema
        if typeMatcher.isInlinable(schema) || typeMatcher.isReferenceableMultipart(content) {
            let decls: [Declaration]
            if contentType.isMultipart {
                decls = try translateMultipartBody(typedContent)
            } else {
                decls = try translateSchema(
                    typeName: typedContent.resolvedTypeUsage.typeName,
                    schema: typedContent.content.schema,
                    overrides: .none
                )
            }
            bodyCases.append(contentsOf: decls)
        }

        let bodyCase: Declaration = .commentable(
            contentType.docComment(typeName: bodyTypeName),
            .enumCase(name: identifier, kind: .nameWithAssociatedValues([.init(type: .init(associatedType))]))
        )
        bodyCases.append(bodyCase)

        var throwingGetterSwitchCases = [
            SwitchCaseDescription(
                kind: .case(.dot(identifier), ["body"]),
                body: [.expression(.return(.identifierPattern("body")))]
            )
        ]
        // We only generate the default branch if there is more than one case to prevent
        // a warning when compiling the generated code.
        if hasMultipleContentTypes {
            throwingGetterSwitchCases.append(
                SwitchCaseDescription(
                    kind: .default,
                    body: [
                        .expression(
                            .try(
                                .identifierPattern("throwUnexpectedResponseBody")
                                    .call([
                                        .init(
                                            label: "expectedContent",
                                            expression: .literal(.string(contentType.headerValueForValidation))
                                        ), .init(label: "body", expression: .identifierPattern("self")),
                                    ])
                            )
                        )
                    ]
                )
            )
        }
        let throwingGetter = VariableDescription(
            accessModifier: config.access,
            isStatic: false,
            kind: .var,
            left: .identifierPattern(identifier),
            type: .init(associatedType),
            getter: [
                .expression(.switch(switchedExpression: .identifierPattern("self"), cases: throwingGetterSwitchCases))
            ],
            getterEffects: [.throws]
        )
        let throwingGetterComment = Comment.doc(
            """
            The associated value of the enum case if `self` is `.\(identifier)`.

            - Throws: An error if `self` is not `.\(identifier)`.
            - SeeAlso: `.\(identifier)`.
            """
        )
        bodyCases.append(.commentable(throwingGetterComment, .variable(throwingGetter)))
        return bodyCases
    }
}
