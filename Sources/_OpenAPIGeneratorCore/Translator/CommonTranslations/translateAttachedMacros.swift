//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
extension Declaration {

    /// Returns the declaration with the provided macros attached after any top comment.
    /// - Parameter macros: The macros to attach.
    /// - Returns: The declaration, unchanged if `macros` is empty.
    func attaching(_ macros: [AttachedMacro]) -> Self {
        guard !macros.isEmpty else { return self }
        let attributes = macros.map(AttributeDescription.init)
        if case .commentable(let comment, let declaration) = self {
            return .commentable(comment, .attributed(attributes, declaration))
        }
        return .attributed(attributes, self)
    }
}

extension Array where Element == Declaration {

    /// Returns the declarations with the provided macros attached to the last one.
    ///
    /// Translating a component returns any inline types first, followed by the type of the component itself.
    /// - Parameter macros: The macros to attach.
    /// - Returns: The declarations.
    func attachingToLast(_ macros: [AttachedMacro]) -> Self {
        guard let last else { return self }
        return dropLast() + [last.attaching(macros)]
    }
}

extension AttributeDescription {

    /// Creates an attribute from an attached macro.
    /// - Parameter macro: The attached macro.
    init(_ macro: AttachedMacro) {
        self.init(
            name: macro.name,
            arguments: macro.arguments.map { argument in
                guard let label = argument.label else { return argument.value }
                return "\(label): \(argument.value)"
            }
        )
    }
}
