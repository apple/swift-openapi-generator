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
    /// - Returns: A list of declarations. Returns a single element in the list
    /// if only the type for the schema needs to be declared. Returns an empty
    /// list if the specified schema is unsupported. Returns multiple elements
    /// if the specified schema contains unnamed types that need to be declared
    /// inline.
    /// - Throws: An error if there is an issue during the matching process.
    func translateSchema(
        componentKey: OpenAPI.ComponentKey,
        schema: JSONSchema
    ) throws -> [Declaration] {
        guard
            try validateSchemaIsSupported(
                schema,
                foundIn: "#/components/schemas/\(componentKey.rawValue)"
            )
        else {
            return []
        }
        let typeName = typeAssigner.typeName(for: (componentKey, schema))
        return try translateSchema(
            typeName: typeName,
            schema: schema,
            overrides: .none
        )
    }

    /// Returns a declaration of the namespace that contains all the reusable
    /// schema definitions.
    /// - Parameter schemas: The schemas from the OpenAPI document.
    /// - Returns: A declaration of the schemas namespace in the parent
    /// components namespace.
    /// - Throws: An error if there is an issue during schema translation.
    func translateSchemas(
        _ schemas: OpenAPI.ComponentDictionary<JSONSchema>
    ) throws -> Declaration {

        let decls: [Declaration] = try schemas.flatMap { key, value in
            try translateSchema(componentKey: key, schema: value)
        }

        let declsHandlingRecursion = try boxRecursiveTypes(decls)
        let componentsSchemasEnum = Declaration.commentable(
            JSONSchema.sectionComment(),
            .enum(
                accessModifier: config.access,
                name: Constants.Components.Schemas.namespace,
                members: declsHandlingRecursion
            )
        )
        return componentsSchemasEnum
    }

    // TODO: Find a better place for this.
    private func boxRecursiveTypes(_ decls: [Declaration]) throws -> [Declaration] {

        let nodes = decls.compactMap(DeclarationRecursionDetector.Node.init)
        let nodeLookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.name, $0) })
        let container = DeclarationRecursionDetector.Container(
            lookupMap: nodeLookup
        )

        let boxedNames = try RecursionDetector.computeBoxedTypes(
            rootNodes: nodes,
            container: container
        )

        var decls = decls
        for (index, decl) in decls.enumerated() {
            guard let name = decl.name, boxedNames.contains(name) else {
                continue
            }
            print(
                "The type '\(name)' will use a copy-on-write reference type for storage, because it is part of a reference cycle."
            )
            decls[index] = boxedType(decl)
        }
        return decls
    }

    private func boxedType(_ decl: Declaration) -> Declaration {
        // TODO: Do the transformation here.

        // For structs:

        // - Move down:
        //      - Properties (and duplicate at top level with set/get), remove comments
        //      - Initializer (although can probably be removed as synthesized one works for private), remove comments
        //      - any existing custom encoder/decoder
        // - Keep at the same level:
        //      - Inline types
        // - Generate a typealias for the coding keys in the Storage type (if a CodingKeys is explicitly defined at the top level).
        // - Generate explicit encoder/decoder.
        //
        // Since we use fully qualified type names, references to inline
        // types don't need to change, even as the property moves down.

        // For enums:

        // Just mark it as indirect, done.

        decl
    }
}
