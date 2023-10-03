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

extension TypeName {

    /// Returns the type name for the String type.
    static var string: Self {
        .swift("String")
    }

    /// Returns the type name for the Int type.
    static var int: Self {
        .swift("Int")
    }

    /// Returns a type name for a type with the specified name in the
    /// Swift module.
    /// - Parameter name: The name of the type.
    static func swift(_ name: String) -> TypeName {
        TypeName(swiftKeyPath: ["Swift", name])
    }

    /// Returns a type name for a type with the specified name in the
    /// Foundation module.
    /// - Parameter name: The name of the type.
    static func foundation(_ name: String) -> TypeName {
        TypeName(swiftKeyPath: ["Foundation", name])
    }

    /// Returns a type name for a type with the specified name in the
    /// OpenAPIRuntime module.
    /// - Parameter name: The name of the type.
    static func runtime(_ name: String) -> TypeName {
        TypeName(swiftKeyPath: ["OpenAPIRuntime", name])
    }

    /// Returns a type name for a type with the specified name in the
    /// HTTPTypes module.
    /// - Parameter name: The name of the type.
    static func httpTypes(_ name: String) -> TypeName {
        TypeName(swiftKeyPath: ["HTTPTypes", name])
    }

    /// Returns the type name for the UndocumentedPayload type.
    static var undocumentedPayload: Self {
        .runtime(Constants.Operation.Output.undocumentedCaseAssociatedValueTypeName)
    }

    /// Returns the type name of generic JSON payload.
    static var valueContainer: TypeName {
        .runtime("OpenAPIValueContainer")
    }

    /// Returns the type name of an object of generic JSON payload.
    static var objectContainer: TypeName {
        .runtime("OpenAPIObjectContainer")
    }

    /// Returns the type name of an array of generic JSON payload.
    static var arrayContainer: TypeName {
        .runtime("OpenAPIArrayContainer")
    }

    /// Returns the type name for the request type.
    static var request: TypeName {
        .httpTypes("HTTPRequest")
    }

    /// Returns the type name for the body type.
    static var body: TypeName {
        .runtime("HTTPBody")
    }
}
