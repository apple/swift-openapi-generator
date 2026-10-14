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

/// A set of configuration values provided by the user.
///
/// In contrast to `Config`, `_UserConfig` supports running multiple invocations
/// of the generator pipeline, and, for example, generate both Types.swift and
/// Client.swift in one invocation of the command-line tool.
package struct _UserConfig: Codable {

    /// A list of modes to use, in other words, which Swift files to generate.
    package var generate: [GeneratorMode]

    /// The access modifier used for the API of generated code.
    package var accessModifier: AccessModifier?

    /// A list of names of additional imports that are added to every
    /// generated Swift file.
    package var additionalImports: [String]?

    /// A list of additional comments that are added to the top of every
    /// generated Swift file.
    package var additionalFileComments: [String]?

    /// Filter to apply to the OpenAPI document before generation.
    package var filter: DocumentFilter?

    /// The strategy to use for naming generated Swift types and members.
    package var namingStrategy: NamingStrategy?

    /// A dictionary of name overrides for generated types and members.
    ///
    /// Any names not included use the `namingStrategy` to compute a Swift name.
    package var nameOverrides: [String: String]?

    /// A dictionary of overrides for replacing the types of generated with manually provided types
    package var typeOverrides: TypeOverrides?

    /// A set of features to explicitly enable.
    package var featureFlags: FeatureFlags?

    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - generate: A list of modes to use, in other words, which Swift files to generate.
    ///   - accessModifier: The access modifier used for the API of generated code.
    ///   - additionalImports: A list of names of additional imports that are added to every generated Swift file.
    ///   - additionalFileComments: A list of additional comments that are added to the top of every generated Swift file.
    ///   - filter: Filter to apply to the OpenAPI document before generation.
    ///   - namingStrategy: The strategy to use for naming generated Swift types and members.
    ///   - nameOverrides: A dictionary of name overrides for generated types and members.
    ///   - typeOverrides: A dictionary of overrides for replacing the types of generated with manually provided types.
    ///   - featureFlags: A set of features to explicitly enable.
    package init(
        generate: [GeneratorMode],
        accessModifier: AccessModifier? = nil,
        additionalImports: [String]? = nil,
        additionalFileComments: [String]? = nil,
        filter: DocumentFilter? = nil,
        namingStrategy: NamingStrategy? = nil,
        nameOverrides: [String: String]? = nil,
        typeOverrides: TypeOverrides? = nil,
        featureFlags: FeatureFlags? = nil
    ) {
        self.generate = generate
        self.accessModifier = accessModifier
        self.additionalImports = additionalImports
        self.additionalFileComments = additionalFileComments
        self.filter = filter
        self.namingStrategy = namingStrategy
        self.nameOverrides = nameOverrides
        self.typeOverrides = typeOverrides
        self.featureFlags = featureFlags
    }

    /// A set of raw values corresponding to the coding keys of this struct.
    package static let codingKeysRawValues = Set(CodingKeys.allCases.map({ $0.rawValue }))

    enum CodingKeys: String, CaseIterable, CodingKey {
        case generate
        case accessModifier
        case additionalImports
        case additionalFileComments
        case filter
        case namingStrategy
        case nameOverrides
        case typeOverrides
        case featureFlags
    }

    /// A container of type overrides.
    package struct TypeOverrides: Codable {
        /// A dictionary of overrides for replacing the types generated from schemas with manually provided types.
        package var schemas: [String: String]?
    }
}
