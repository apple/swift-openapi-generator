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

    /// Returns a list of declarations for the provided schema, defined in the
    /// OpenAPI document under the specified component key.
    ///
    /// The last declaration is the type declaration for the schema.
    /// - Parameters:
    ///   - componentKey: The key for the schema, specified in the OpenAPI
    ///   document.
    ///   - schema: The schema to translate to a Swift type.
    ///   - isMultipartContent: A Boolean value indicating whether the schema defines multipart parts.
    /// - Returns: A list of declarations. Returns a single element in the list
    /// if only the type for the schema needs to be declared. Returns an empty
    /// list if the specified schema is unsupported. Returns multiple elements
    /// if the specified schema contains unnamed types that need to be declared
    /// inline.
    /// - Throws: An error if there is an issue during the matching process.
    func translateSchema(componentKey: OpenAPI.ComponentKey, schema: JSONSchema, isMultipartContent: Bool) throws
        -> [Declaration]
    {
        guard try validateSchemaIsSupported(schema, foundIn: "#/components/schemas/\(componentKey.rawValue)") else {
            return []
        }
        let typeName = typeAssigner.typeName(for: (componentKey, schema))
        return try translateSchema(
            typeName: typeName,
            schema: schema,
            overrides: .none,
            isMultipartContent: isMultipartContent
        )
    }

    /// Returns a declaration of the namespace that contains all the reusable
    /// schema definitions.
    /// - Parameters:
    ///   - schemas: The schemas from the OpenAPI document.
    ///   - multipartSchemaNames: The names of schemas used as root multipart content.
    /// - Returns: A declaration of the schemas namespace in the parent
    /// components namespace.
    /// - Throws: An error if there is an issue during schema translation.
    func translateSchemas(
        _ schemas: OpenAPI.ComponentDictionary<JSONSchema>,
        multipartSchemaNames: Set<OpenAPI.ComponentKey>
    ) throws -> Declaration {

        let decls: [Declaration] = try schemas.flatMap { key, value in
            try translateSchema(
                componentKey: key,
                schema: value,
                isMultipartContent: multipartSchemaNames.contains(key)
            )
        }
        let declsWithBoxingApplied = try boxRecursiveTypes(decls)
        let componentsSchemasEnum = Declaration.commentable(
            JSONSchema.sectionComment(),
            .enum(
                accessModifier: config.access,
                name: Constants.Components.Schemas.namespace,
                members: declsWithBoxingApplied
            )
        )
        return componentsSchemasEnum
    }
}
