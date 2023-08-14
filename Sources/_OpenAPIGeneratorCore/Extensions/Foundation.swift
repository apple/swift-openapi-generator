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
import Foundation

extension Data {
    /// A copy of the data formatted using swift-format.
    ///
    /// Data is assumed to contain Swift code encoded using UTF-8.
    ///
    /// - Throws: When data is not valid UTF-8.
    var swiftFormatted: Data {
        get throws {
            let string = String(decoding: self, as: UTF8.self)
            return try Self(string.swiftFormatted.utf8)
        }
    }
}

extension InMemoryInputFile {
    /// Creates a new in-memory file by reading the contents at the specified path.
    /// - Parameter url: The path to the file to read.
    init(fromFileAt url: URL) throws {
        try self.init(absolutePath: url, contents: Data(contentsOf: url))
    }
}

extension InMemoryOutputFile {
    /// A copy of the file formatted using swift-format.
    public var swiftFormatted: InMemoryOutputFile {
        get throws {
            var new = self
            new.contents = try contents.swiftFormatted
            return new
        }
    }
}

/// File handle to stderr.
let stdErrHandle = FileHandle.standardError

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        write(Data(string.utf8))
    }
}
