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
public enum NamingStrategy: String, Sendable, Codable, Equatable, CaseIterable {

    /// A defensive strategy that can handle any OpenAPI identifier and produce a non-conflicting Swift identifier.
    ///
    /// Introduced in [SOAR-0001](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0001).
    case defensive

    /// An idiomatic strategy that produces Swift identifiers that more likely conform to Swift conventions.
    ///
    /// Introduced in [SOAR-0013](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0013).
    case idiomatic
}

/// Configuration for sharding the generated Types file into multiple files
/// organized by dependency layers.
public struct ShardingConfig: Sendable, Equatable {
    /// The number of type shards per layer (index 0 = component/leaf layer,
    /// index 1+ = dependent layers).
    public var typeShardCounts: [Int]
    /// Maximum Swift files per shard for type schemas.
    public var maxFilesPerShard: Int
    /// Maximum Swift files per shard for operations.
    public var maxFilesPerShardOps: Int
    /// The number of shards per operation layer (index = layer number).
    /// Must have exactly `layerCount` entries.
    public var operationLayerShardCounts: [Int]
    /// Module prefix for deterministic file naming (e.g., "MyServiceAPI").
    /// When set, produces deterministic file names suitable for build-system integration.
    public var modulePrefix: String?

    /// The total number of dependency layers.
    public var layerCount: Int { typeShardCounts.count }

    /// Returns the number of type shards for the given layer index.
    public func typeShardCount(forLayer layerIndex: Int) -> Int {
        typeShardCounts[layerIndex]
    }

    public init(
        typeShardCounts: [Int],
        maxFilesPerShard: Int = 25,
        maxFilesPerShardOps: Int = 16,
        operationLayerShardCounts: [Int],
        modulePrefix: String? = nil
    ) {
        self.typeShardCounts = typeShardCounts
        self.maxFilesPerShard = maxFilesPerShard
        self.maxFilesPerShardOps = maxFilesPerShardOps
        self.operationLayerShardCounts = operationLayerShardCounts
        self.modulePrefix = modulePrefix
    }

    public enum ValidationError: Error, CustomStringConvertible {
        case nonPositiveShardCount(field: String, value: Int)
        case shardCountMismatch(field: String, expected: Int, got: Int)

        public var description: String {
            switch self {
            case .nonPositiveShardCount(let field, let value):
                return "\(field) must be > 0, got \(value)"
            case .shardCountMismatch(let field, let expected, let got):
                return "\(field) count (\(got)) must equal layerCount (\(expected))"
            }
        }
    }

    public func validate() throws {
        func requirePositive(_ value: Int, field: String) throws {
            guard value > 0 else {
                throw ValidationError.nonPositiveShardCount(field: field, value: value)
            }
        }
        for (index, count) in typeShardCounts.enumerated() {
            try requirePositive(count, field: "typeShardCounts[\(index)]")
        }
        try requirePositive(maxFilesPerShard, field: "maxFilesPerShard")
        try requirePositive(maxFilesPerShardOps, field: "maxFilesPerShardOps")
        for (index, count) in operationLayerShardCounts.enumerated() {
            try requirePositive(count, field: "operationLayerShardCounts[\(index)]")
        }
        if operationLayerShardCounts.count != layerCount {
            throw ValidationError.shardCountMismatch(
                field: "operationLayerShardCounts",
                expected: layerCount,
                got: operationLayerShardCounts.count
            )
        }
    }
}

extension ShardingConfig: Codable {}

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

    /// Additional comments to add to the top of each generated file.
    public var additionalFileComments: [String]

    /// Filter to apply to the OpenAPI document before generation.
    public var filter: DocumentFilter?

    /// The naming strategy to use for deriving Swift identifiers from OpenAPI identifiers.
    ///
    /// Defaults to `defensive`.
    public var namingStrategy: NamingStrategy

    /// The default naming strategy.
    public static let defaultNamingStrategy: NamingStrategy = .defensive

    /// A map of OpenAPI identifiers to desired Swift identifiers, used instead of the naming strategy.
    public var nameOverrides: [String: String]
    /// A map of OpenAPI schema names to desired custom type names.
    public var typeOverrides: TypeOverrides

    /// Additional pre-release features to enable.
    public var featureFlags: FeatureFlags

    /// Optional sharding configuration for splitting Types output into multiple files.
    public var sharding: ShardingConfig?

    /// Creates a configuration with the specified generator mode and imports.
    /// - Parameters:
    ///   - mode: The mode to use for generation.
    ///   - access: The access modifier to use for generated declarations.
    ///   - additionalImports: Additional imports to add to each generated file.
    ///   - additionalFileComments: Additional comments to add to the top of each generated file.
    ///   - filter: Filter to apply to the OpenAPI document before generation.
    ///   - namingStrategy: The naming strategy to use for deriving Swift identifiers from OpenAPI identifiers.
    ///     Defaults to `defensive`.
    ///   - nameOverrides: A map of OpenAPI identifiers to desired Swift identifiers, used instead
    ///     of the naming strategy.
    ///   - typeOverrides: A map of OpenAPI schema names to desired custom type names.
    ///   - featureFlags: Additional pre-release features to enable.
    public init(
        mode: GeneratorMode,
        access: AccessModifier,
        additionalImports: [String] = [],
        additionalFileComments: [String] = [],
        filter: DocumentFilter? = nil,
        namingStrategy: NamingStrategy,
        nameOverrides: [String: String] = [:],
        typeOverrides: TypeOverrides = .init(),
        featureFlags: FeatureFlags = [],
        sharding: ShardingConfig? = nil
    ) {
        self.mode = mode
        self.access = access
        self.additionalImports = additionalImports
        self.additionalFileComments = additionalFileComments
        self.filter = filter
        self.namingStrategy = namingStrategy
        self.nameOverrides = nameOverrides
        self.typeOverrides = typeOverrides
        self.featureFlags = featureFlags
        self.sharding = sharding
    }
}
