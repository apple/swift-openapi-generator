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

    /// Returns a declaration of the reusable request bodies defined
    /// in the OpenAPI document.
    /// - Parameter items: The reusable request bodies.
    /// - Returns: An enum declaration representing the requestBodies namespace.
    /// - Throws: An error if there's an issue during translation or request body processing.
    func translateComponentRequestBodies(_ items: OpenAPI.ComponentDictionary<OpenAPI.Request>) throws -> Declaration {
        let typedItems: [TypedRequestBody] = try items.compactMap { key, item in
            let typeName = typeAssigner.typeName(for: key, of: OpenAPI.Request.self)
            return try typedRequestBody(typeName: typeName, from: .b(item))
        }
        let decls: [Declaration] = try typedItems.map { value in try translateRequestBodyInTypes(requestBody: value) }

        let componentsEnum = Declaration.commentable(
            OpenAPI.Request.sectionComment(),
            .enum(accessModifier: config.access, name: Constants.Components.RequestBodies.namespace, members: decls)
        )
        return componentsEnum
    }
}
