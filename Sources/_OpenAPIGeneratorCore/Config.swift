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

/// A strategy for turning OpenAPI identifiers into Swift identifiers.
public enum NamingStrategy: String, Sendable, Codable, Equatable {

    /// A defensive strategy that can handle any OpenAPI identifier and produce a non-conflicting Swift identifier.
    ///
    /// Introduced in [SOAR-0001](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0001).
    case defensive

    /// An idiomatic strategy that produces Swift identifiers that more likely conform to Swift conventions.
    ///
    /// Introduced in [SOAR-0013](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0013).
    case idiomatic
}

/// A structure that contains configuration options for a single execution
/// of the generator pipeline run.
///
/// A single generator pipeline run produces exactly one file, so for
/// generating multiple files, create multiple configuration values, each with
/// a different generator mode.
public struct Config: Sendable {

    /// The generator mode to use.
    public var mode: GeneratorMode

    /// The access modifier to use for generated declarations.
    public var access: AccessModifier

    /// The default access modifier.
    public static let defaultAccessModifier: AccessModifier = .internal

    /// Additional imports to add to each generated file.
    public var additionalImports: [String]

    /// Filter to apply to the OpenAPI document before generation.
    public var filter: DocumentFilter?

    /// The naming strategy to use for deriving Swift identifiers from OpenAPI identifiers.
    ///
    /// Defaults to `defensive`.
    public var namingStrategy: NamingStrategy

    /// A map of OpenAPI identifiers to desired Swift identifiers, used instead of the naming strategy.
    public var nameOverrides: [String: String]

    /// Additional pre-release features to enable.
    public var featureFlags: FeatureFlags

    /// Creates a configuration with the specified generator mode and imports.
    /// - Parameters:
    ///   - mode: The mode to use for generation.
    ///   - access: The access modifier to use for generated declarations.
    ///   - additionalImports: Additional imports to add to each generated file.
    ///   - filter: Filter to apply to the OpenAPI document before generation.
    ///   - namingStrategy: The naming strategy to use for deriving Swift identifiers from OpenAPI identifiers.
    ///     Defaults to `defensive`.
    ///   - nameOverrides: A map of OpenAPI identifiers to desired Swift identifiers, used instead
    ///     of the naming strategy.
    ///   - featureFlags: Additional pre-release features to enable.
    public init(
        mode: GeneratorMode,
        access: AccessModifier,
        additionalImports: [String] = [],
        filter: DocumentFilter? = nil,
        namingStrategy: NamingStrategy = .defensive,
        nameOverrides: [String: String] = [:],
        featureFlags: FeatureFlags = []
    ) {
        self.mode = mode
        self.access = access
        self.additionalImports = additionalImports
        self.filter = filter
        self.namingStrategy = namingStrategy
        self.nameOverrides = nameOverrides
        self.featureFlags = featureFlags
    }
}
