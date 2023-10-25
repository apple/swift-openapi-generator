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

import OpenAPIKit

/// A stack with efficient checking if a specific item is included.
struct ReferenceStack {

    /// The current stack of names.
    private var stack: [String]

    /// The names seen so far.
    private var names: Set<String>

    /// Creates a new stack.
    /// - Parameters:
    ///   - stack: The initial stack of names.
    ///   - names: The names seen so far.
    init(stack: [String], names: Set<String>) {
        self.stack = stack
        self.names = names
    }

    /// An empty stack.
    static var empty: Self { .init(stack: [], names: []) }

    /// Pushes the provided name to the stack.
    /// - Parameter name: The name to push.
    mutating func push(_ name: String) {
        stack.append(name)
        names.insert(name)
    }

    /// Pushes the provided ref to the stack.
    /// - Parameter ref: The ref to push.
    /// - Throws: When the reference isn't an internal component one.
    mutating func push(_ ref: JSONReference<JSONSchema>) throws { try push(ref.requiredName) }

    /// Removes the top item from the stack.
    mutating func pop() {
        let name = stack.removeLast()
        names.remove(name)
    }

    /// Returns whether the provided name is present in the stack.
    /// - Parameter name: The name to check.
    /// - Returns: `true` if present, `false` otherwise.
    func contains(_ name: String) -> Bool { names.contains(name) }

    /// Returns whether the provided ref is present in the stack.
    /// - Parameter ref: The ref to check.
    /// - Returns: `true` if present, `false` otherwise.
    /// - Throws: When the reference isn't an internal component one.
    func contains(_ ref: JSONReference<JSONSchema>) throws -> Bool { try contains(ref.requiredName) }
}

extension JSONReference<JSONSchema> {

    /// Returns the name of the reference.
    ///
    /// - Throws: If the reference is not an internal component one.
    var requiredName: String {
        get throws {
            guard case .internal(let internalReference) = self, case .component(name: let name) = internalReference
            else { throw JSONReferenceParsingError.externalPathsUnsupported(absoluteString) }
            return name
        }
    }
}
