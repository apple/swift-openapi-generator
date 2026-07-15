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
        try detectDuplicateGeneratedNames(in: decls)
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

    /// Emits a clear error if multiple generated schema declarations map to the
    /// same Swift type name, instead of letting a later step crash on the
    /// collision.
    /// - Parameter decls: The declarations of `Components.Schemas.*` types.
    /// - Throws: An error describing the colliding names.
    private func detectDuplicateGeneratedNames(in decls: [Declaration]) throws {
        var seenNames: Set<String> = []
        var duplicateNames: Set<String> = []
        for name in decls.compactMap(\.name) {
            if !seenNames.insert(name).inserted { duplicateNames.insert(name) }
        }
        guard !duplicateNames.isEmpty else { return }
        let sortedNames = duplicateNames.sorted()
        let message: String
        let context: [String: String]
        if sortedNames.count == 1 {
            let duplicateName = sortedNames[0]
            message =
                "Multiple schemas in '#/components/schemas' map to the same generated Swift type name '\(duplicateName)', which is not supported. This usually happens when the naming strategy collapses two distinct OpenAPI names into one. Switch the namingStrategy to 'defensive', or add a 'nameOverrides' entry to give one of the schemas a different name."
            context = ["name": duplicateName]
        } else {
            let nameList = sortedNames.map { "'\($0)'" }.joined(separator: ", ")
            message =
                "Multiple schemas in '#/components/schemas' map to the same generated Swift type names \(nameList), which is not supported. This usually happens when the naming strategy collapses distinct OpenAPI names into one. Switch the namingStrategy to 'defensive', or add 'nameOverrides' entries to give the schemas different names."
            context = ["names": nameList]
        }
        try diagnostics.emit(.error(message: message, context: context))
    }
}
