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

    /// Returns a declaration of the reusable response headers defined
    /// in the OpenAPI document.
    /// - Parameter headers: The reusable response headers.
    /// - Returns: An enum declaration representing the headers namespace.
    /// - Throws: An error if there's an issue during translation or header processing.
    func translateComponentHeaders(_ headers: OpenAPI.ComponentDictionary<OpenAPI.Header>) throws -> Declaration {

        let typedHeaders: [(OpenAPI.ComponentKey, TypedResponseHeader)] = try headers.compactMap { key, header in
            let parent = typeAssigner.typeName(for: key, of: OpenAPI.Header.self)
            guard let value = try typedResponseHeader(from: .b(header), named: key.rawValue, inParent: parent) else {
                return nil
            }
            return (key, value)
        }
        let decls: [Declaration] = try typedHeaders.flatMap { key, value in
            try translateResponseHeaderInTypes(componentKey: key, header: value)
        }

        let componentsParametersEnum = Declaration.commentable(
            OpenAPI.Header.sectionComment(),
            .enum(accessModifier: config.access, name: Constants.Components.Headers.namespace, members: decls)
        )
        return componentsParametersEnum
    }
}
