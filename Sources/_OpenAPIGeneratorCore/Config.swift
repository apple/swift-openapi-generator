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

    /// Additional imports to add to each generated file.
    public var additionalImports: [String]

    /// Additional pre-release features to enable.
    public var featureFlags: FeatureFlags

    /// Creates a configuration with the specified generator mode and imports.
    /// - Parameters:
    ///   - mode: The mode to use for generation.
    ///   - additionalImports: Additional imports to add to each generated file.
    ///   - featureFlags: Additional pre-release features to enable.
    public init(
        mode: GeneratorMode,
        additionalImports: [String] = [],
        featureFlags: FeatureFlags = []
    ) {
        self.mode = mode
        self.additionalImports = additionalImports
        self.featureFlags = featureFlags
    }
}

extension Config {
    /// Returns the access modifier to use for generated declarations.
    var access: AccessModifier? {
        .public
    }
}
