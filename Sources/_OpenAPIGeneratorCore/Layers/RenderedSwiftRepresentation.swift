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
#if os(Linux)
@preconcurrency public import struct Foundation.URL
@preconcurrency public import struct Foundation.Data
#else
public import struct Foundation.URL
public import struct Foundation.Data
#endif

/// In-memory output files emitted by rendering a generator pipeline run.
typealias RenderedSwiftRepresentation = [InMemoryOutputFile]

/// An in-memory input file that contains the raw data of an OpenAPI document.
///
/// Contents are formatted as either YAML or JSON.
public struct InMemoryInputFile: Sendable {

    /// The absolute path to the file.
    public var absolutePath: URL

    /// The YAML or JSON file contents encoded as UTF-8 data.
    public var contents: Data

    /// Creates a file with the specified path and contents.
    /// - Parameters:
    ///   - absolutePath: An absolute path to the file.
    ///   - contents: Data contents of the file, encoded as UTF-8.
    public init(absolutePath: URL, contents: Data) {
        self.absolutePath = absolutePath
        self.contents = contents
    }
}

/// An in-memory output file that contains the generated Swift source code.
public struct InMemoryOutputFile: Sendable {

    /// The base name of the file.
    public var baseName: String

    /// The Swift file contents encoded as UTF-8 data.
    public var contents: Data

    /// Semantic planning information for this output, when available.
    public var metadata: GeneratedOutputFileMetadata?

    /// Creates a file with the specified name and contents.
    /// - Parameters:
    ///   - baseName: A base name representing the desired name.
    ///   - contents: Data contents of the file, encoded as UTF-8.
    ///   - metadata: Semantic planning information for the output, when available.
    public init(baseName: String, contents: Data, metadata: GeneratedOutputFileMetadata? = nil) {
        self.baseName = baseName
        self.contents = contents
        self.metadata = metadata
    }
}

/// Generator-owned semantic information about an emitted Swift file.
public struct GeneratedOutputFileMetadata: Sendable, Equatable, Codable {

    /// The semantic role of the generated file.
    public var role: String

    /// The generated namespace extended by the file, when applicable.
    public var namespace: String?

    /// The zero-based dependency layer, when dependency layering is enabled.
    public var dependencyLayer: Int?

    /// The zero-based declaration chunk within the role and dependency layer.
    public var declarationChunk: Int?

    /// A stable, Swift-identifier-safe identity derived from the semantic declarations owned by the file.
    public var moduleIdentity: String

    /// Semantic declaration identifiers owned by this file.
    public var declarations: [String]

    /// Resolved reusable-schema names directly used by declarations in this file.
    public var schemaDependencies: [String]

    /// Resolved reusable-component identifiers directly used by declarations in this file.
    public var componentDependencies: [String]

    /// Creates semantic planning information for an emitted Swift file.
    public init(
        role: String,
        namespace: String?,
        dependencyLayer: Int?,
        declarationChunk: Int?,
        moduleIdentity: String,
        declarations: [String],
        schemaDependencies: [String],
        componentDependencies: [String]
    ) {
        self.role = role
        self.namespace = namespace
        self.dependencyLayer = dependencyLayer
        self.declarationChunk = declarationChunk
        self.moduleIdentity = moduleIdentity
        self.declarations = declarations
        self.schemaDependencies = schemaDependencies
        self.componentDependencies = componentDependencies
    }
}

extension InMemoryOutputFile: Comparable {
    /// Compares two `InMemoryOutputFile` instances based on `baseName` and contents for ordering.
    public static func < (lhs: InMemoryOutputFile, rhs: InMemoryOutputFile) -> Bool {
        guard lhs.baseName == rhs.baseName else { return lhs.baseName < rhs.baseName }
        return lhs.contents.base64EncodedString() < rhs.contents.base64EncodedString()
    }
}
