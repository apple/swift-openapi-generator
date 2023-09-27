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

extension FileTranslator {

    /// Returns a list of declarations for an array schema.
    ///
    /// The last declaration in the list is for the typealias for the array,
    /// but any additional declarations in the array might be for nested types
    /// defined as unnamed schemas in the OpenAPI document.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared array.
    ///   - openAPIDescription: A user-specified description from the OpenAPI
    ///   document.
    ///   - arrayContext: The context for the array, including information such
    ///   as the element schema.
    func translateArray(
        typeName: TypeName,
        openAPIDescription: String?,
        arrayContext: JSONSchema.ArrayContext
    ) throws -> [Declaration] {

        var inline: [Declaration] = []

        // An OpenAPI array is represented as a Swift array with an element type
        let elementType: TypeUsage
        if let items = arrayContext.items {
            if let builtinType = try typeMatcher.tryMatchReferenceableType(
                for: items,
                components: components
            ) {
                elementType = builtinType
            } else {
                elementType = try typeAssigner.typeUsage(
                    forArrayElementWithSchema: items,
                    components: components,
                    inParent: typeName
                )
                let nestedDecls = try translateSchema(
                    typeName: elementType.typeName,
                    schema: items,
                    overrides: .none
                )
                inline.append(contentsOf: nestedDecls)
            }
        } else {
            elementType = TypeName.valueContainer.asUsage
        }

        let typealiasComment: Comment? =
            typeName
            .docCommentWithUserDescription(openAPIDescription)
        let arrayDecl: Declaration = .commentable(
            typealiasComment,
            .`typealias`(
                accessModifier: config.access,
                name: typeName.shortSwiftName,
                existingType: elementType.typeName.asUsage.asArray.fullyQualifiedSwiftName
            )
        )
        return inline + [arrayDecl]
    }
}
