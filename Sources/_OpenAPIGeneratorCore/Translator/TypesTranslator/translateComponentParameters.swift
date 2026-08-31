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

    /// Returns a declaration of the reusable request parameters defined
    /// in the OpenAPI document.
    /// - Parameter parameters: The reusable request parameters.
    /// - Returns: An enum declaration representing the parameters namespace.
    /// - Throws: An error if there's an issue during translation or parameter processing.
    func translateComponentParameters(_ parameters: OpenAPI.ComponentDictionary<OpenAPI.Parameter>) throws
        -> Declaration
    {

        let decls = try translateComponentParameterDeclarationGroups(parameters).flatMap(\.declarations)

        let componentsParametersEnum = Declaration.commentable(
            OpenAPI.Parameter.sectionComment(),
            .enum(accessModifier: config.access, name: Constants.Components.Parameters.namespace, members: decls)
        )
        return componentsParametersEnum
    }

    func translateComponentParameterDeclarationGroups(_ parameters: OpenAPI.ComponentDictionary<OpenAPI.Parameter>)
        throws -> [OwnedDeclarations]
    {
        let typedParameters: [(OpenAPI.ComponentKey, TypedParameter)] = try parameters.compactMap { key, parameter in
            let parent = typeAssigner.typeName(for: key, of: OpenAPI.Parameter.self)
            guard let value = try parseAsTypedParameter(from: .b(parameter), inParent: parent) else { return nil }
            return (key, value)
        }
        return try typedParameters.map { key, value in
            OwnedDeclarations(
                owner: key.rawValue,
                declarations: try translateParameterInTypes(componentKey: key, parameter: value)
            )
        }
    }
}
