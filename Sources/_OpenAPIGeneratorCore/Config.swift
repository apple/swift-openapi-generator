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

    /// Additional pre-release features to enable.
    public var featureFlags: FeatureFlags

    /// Creates a configuration with the specified generator mode and imports.
    /// - Parameters:
    ///   - mode: The mode to use for generation.
    ///   - access: The access modifier to use for generated declarations.
    ///   - additionalImports: Additional imports to add to each generated file.
    ///   - filter: Filter to apply to the OpenAPI document before generation.
    ///   - featureFlags: Additional pre-release features to enable.
    public init(
        mode: GeneratorMode,
        access: AccessModifier,
        additionalImports: [String] = [],
        filter: DocumentFilter? = nil,
        featureFlags: FeatureFlags = []
    ) {
        self.mode = mode
        self.access = access
        self.additionalImports = additionalImports
        self.filter = filter
        self.featureFlags = featureFlags
    }
}
