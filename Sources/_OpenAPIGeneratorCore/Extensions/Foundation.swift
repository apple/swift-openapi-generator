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

extension InMemoryInputFile {
    /// Creates a new in-memory file by reading the contents at the specified path.
    /// - Parameter url: The path to the file to read.
    init(fromFileAt url: URL) throws {
        try self.init(absolutePath: url, contents: Data(contentsOf: url))
    }
}

/// File handle to stderr.
var stdErrHandle = FileHandle.standardError

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        write(Data(string.utf8))
    }
}
