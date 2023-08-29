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
    ///   - typedResponse: The typed response to declare.
    /// - Returns: A structure declaration.
    func translateResponseInTypes(
        typeName: TypeName,
        response: TypedResponse
    ) throws -> Declaration {
        let response = response.response
        let headersTypeName = typeName.appending(
            swiftComponent: Constants.Operation.Output.Payload.Headers.typeName,
            jsonComponent: "headers"
        )
        let headers = try typedResponseHeaders(
            from: response,
            inParent: headersTypeName
        )
        let headerProperties: [PropertyBlueprint] = try headers.map { header in
            try parseResponseHeaderAsProperty(
                for: header,
                parent: headersTypeName
            )
        }
        let headerStructComment: Comment? =
            headersTypeName
            .docCommentWithUserDescription(nil)
        let headersStructBlueprint: StructBlueprint = .init(
            comment: headerStructComment,
            access: config.access,
            typeName: headersTypeName,
            conformances: Constants.Operation.Output.Payload.Headers.conformances,
            properties: headerProperties
        )
        let headersStructDecl = translateStructBlueprint(
            headersStructBlueprint
        )
        let headersProperty = PropertyBlueprint(
            comment: .doc("Received HTTP response headers"),
            originalName: Constants.Operation.Output.Payload.Headers.variableName,
            typeUsage: headersTypeName.asUsage,
            default: headersStructBlueprint.hasEmptyInit ? .emptyInit : nil,
            associatedDeclarations: [
                headersStructDecl
            ],
            asSwiftSafeName: swiftSafeName
        )

        let bodyTypeName = typeName.appending(
            swiftComponent: Constants.Operation.Body.typeName,
            jsonComponent: "content"
        )
        let typedContents = try supportedTypedContents(
            response.content,
            inParent: bodyTypeName
        )
        var bodyCases: [Declaration] = []
        for typedContent in typedContents {
            let contentType = typedContent.content.contentType
            let identifier = contentSwiftName(contentType)
            let associatedType = typedContent.resolvedTypeUsage
            if TypeMatcher.isInlinable(typedContent.content.schema), let inlineType = typedContent.typeUsage {
                let inlineTypeDecls = try translateSchema(
                    typeName: inlineType.typeName,
                    schema: typedContent.content.schema,
                    overrides: .none
                )
                bodyCases.append(contentsOf: inlineTypeDecls)
            }

            let bodyCase: Declaration = .commentable(
                contentType.docComment(typeName: bodyTypeName),
                .enumCase(
                    name: identifier,
                    kind: .nameWithAssociatedValues([
                        .init(type: associatedType.fullyQualifiedSwiftName)
                    ])
                )
            )
            bodyCases.append(bodyCase)
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
        let contentProperty = PropertyBlueprint(
            comment: .doc("Received HTTP response body"),
            originalName: Constants.Operation.Body.variableName,
            typeUsage: contentTypeUsage,
            default: hasNoContent ? .nil : nil,
            associatedDeclarations: [
                contentEnumDecl
            ],
            asSwiftSafeName: swiftSafeName
        )

        let responseStructDecl = translateStructBlueprint(
            .init(
                comment: nil,
                access: config.access,
                typeName: typeName,
                conformances: Constants.Operation.Output.Payload.conformances,
                properties: [
                    headersProperty,
                    contentProperty,
                ]
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
    func translateResponseHeaderInTypes(
        componentKey: OpenAPI.ComponentKey,
        response: TypedResponse
    ) throws -> Declaration {
        let typeName = typeAssigner.typeName(
            for: componentKey,
            of: OpenAPI.Response.self
        )
        return try translateResponseInTypes(
            typeName: typeName,
            response: response
        )
    }
}
