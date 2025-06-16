//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A container of schema type overrides.
public struct TypeOverrides: Sendable {
    /// A dictionary of overrides for replacing named schemas from the OpenAPI document with custom types.
    public var schemas: [String: String]

    /// Creates a new instance.
    /// - Parameter schemas: A dictionary of overrides for replacing named schemas from the OpenAPI document with custom types.
    public init(schemas: [String: String] = [:]) { self.schemas = schemas }
}
