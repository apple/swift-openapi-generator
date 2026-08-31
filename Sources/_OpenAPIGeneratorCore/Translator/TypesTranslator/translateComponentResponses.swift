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

    /// Returns a declaration of the reusable responses defined
    /// in the OpenAPI document.
    /// - Parameter responses: The reusable responses.
    /// - Returns: An enum declaration representing the responses namespace.
    /// - Throws: An error if there's an issue during translation or request body processing
    func translateComponentResponses(_ responses: OpenAPI.ComponentDictionary<OpenAPI.Response>) throws -> Declaration {

        let decls = try translateComponentResponseDeclarationGroups(responses).flatMap(\.declarations)

        let componentsResponsesEnum = Declaration.commentable(
            OpenAPI.Response.sectionComment(),
            .enum(accessModifier: config.access, name: Constants.Components.Responses.namespace, members: decls)
        )
        return componentsResponsesEnum
    }

    func translateComponentResponseDeclarationGroups(_ responses: OpenAPI.ComponentDictionary<OpenAPI.Response>) throws
        -> [OwnedDeclarations]
    {
        let typedResponses: [(OpenAPI.ComponentKey, TypedResponse)] = responses.map { key, response in
            let typeName = typeAssigner.typeName(for: key, of: OpenAPI.Response.self)
            let value = TypedResponse(response: response, typeUsage: typeName.asUsage, isInlined: false)
            return (key, value)
        }
        return try typedResponses.map { key, value in
            OwnedDeclarations(
                owner: key.rawValue,
                declarations: [try translateResponseInTypes(typeName: value.typeUsage.typeName, response: value)]
            )
        }
    }
}
