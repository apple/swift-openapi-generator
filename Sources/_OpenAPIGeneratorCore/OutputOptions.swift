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

/// Configuration for generated output files.
public struct OutputOptions: Sendable, Codable, Equatable {

    /// Options that only affect `Types.swift` generation.
    public var types: TypesOutputOptions?

    /// Creates output options.
    /// - Parameter types: Options that only affect `Types.swift` generation.
    public init(types: TypesOutputOptions? = nil) { self.types = types }
}

/// Configuration for generated types output files.
public struct TypesOutputOptions: Sendable, Codable, Equatable {

    /// Optional configuration for splitting generated types across files.
    public var fileSplitting: TypesFileSplittingConfig?

    /// Creates types output options.
    /// - Parameter fileSplitting: Optional configuration for splitting generated types across files.
    public init(fileSplitting: TypesFileSplittingConfig? = nil) { self.fileSplitting = fileSplitting }
}

/// Configuration for splitting generated types across files.
public struct TypesFileSplittingConfig: Sendable, Codable, Equatable {

    /// The strategy to use when splitting generated types across files.
    public var strategy: TypesFileSplittingStrategy

    /// Options for the namespace file splitting strategy.
    public var namespace: NamespaceTypesFileSplittingOptions?

    /// Creates a file splitting configuration.
    /// - Parameters:
    ///   - strategy: The strategy to use when splitting generated types across files.
    ///   - namespace: Options for the namespace file splitting strategy.
    public init(
        strategy: TypesFileSplittingStrategy,
        namespace: NamespaceTypesFileSplittingOptions? = nil
    ) {
        self.strategy = strategy
        self.namespace = namespace
    }
}

/// Options for the namespace file splitting strategy.
public struct NamespaceTypesFileSplittingOptions: Sendable, Codable, Equatable {

    /// Creates namespace file splitting options.
    public init() {}
}

/// A strategy for splitting generated types across files.
public enum TypesFileSplittingStrategy: String, Sendable, Codable, Equatable, CaseIterable {

    /// Splits generated types into a small fixed set of files by top-level namespace.
    case namespace
}
