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
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
#else
import struct Foundation.URL
import struct Foundation.Data
#endif

/// An in-memory file that contains the generated Swift code.
typealias RenderedSwiftRepresentation = InMemoryOutputFile

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

    /// Creates a file with the specified name and contents.
    /// - Parameters:
    ///   - baseName: A base name representing the desired name.
    ///   - contents: Data contents of the file, encoded as UTF-8.
    public init(baseName: String, contents: Data) {
        self.baseName = baseName
        self.contents = contents
    }
}

extension InMemoryOutputFile: Comparable {
    /// Compares two `InMemoryOutputFile` instances based on `baseName` and contents for ordering.
    public static func < (lhs: InMemoryOutputFile, rhs: InMemoryOutputFile) -> Bool {
        guard lhs.baseName == rhs.baseName else { return lhs.baseName < rhs.baseName }
        return lhs.contents.base64EncodedString() < rhs.contents.base64EncodedString()
    }
}
