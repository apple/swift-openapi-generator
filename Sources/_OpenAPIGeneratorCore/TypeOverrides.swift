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

public struct TypeOverrides: Sendable {
    /// A dictionary of overrides for replacing the types generated from schemas with manually provided types
    public var schemas: [String: String]

    /// Creates a new instance of `TypeOverrides`
    /// - Parameter schemas: A dictionary mapping schema names to their override types.
    public init(schemas: [String: String] = [:]) { self.schemas = schemas }

    /// A Boolean value indicating whether there are no overrides.
    public var isEmpty: Bool { schemas.isEmpty }
}
