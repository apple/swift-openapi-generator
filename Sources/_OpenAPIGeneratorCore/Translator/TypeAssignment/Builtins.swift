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
    static var string: Self { .swift("String") }

    /// Returns the type name for the Int type.
    static var int: Self { .swift("Int") }

    /// Returns a type name for a type with the specified name in the
    /// Swift module.
    /// - Parameter name: The name of the type.
    /// - Returns: A TypeName representing the specified type within the Swift module.
    static func swift(_ name: String) -> TypeName { TypeName(swiftKeyPath: ["Swift", name]) }

    /// Returns a type name for a type with the specified name in the
    /// Foundation module.
    /// - Parameter name: The name of the type.
    /// - Returns: A TypeName representing the specified type within the Foundation module.
    static func foundation(_ name: String) -> TypeName { TypeName(swiftKeyPath: ["Foundation", name]) }

    /// Returns a type name for a type with the specified name in the
    /// OpenAPIRuntime module.
    /// - Parameter name: The name of the type.
    /// - Returns: A TypeName representing the specified type within the OpenAPIRuntime module.
    static func runtime(_ name: String) -> TypeName { TypeName(swiftKeyPath: [Constants.Import.runtime, name]) }

    /// Returns a type name for a type with the specified name in the
    /// HTTPTypes module.
    /// - Parameter name: The name of the type.
    /// - Returns: A TypeName representing the type with the given name in the HTTPTypes module.
    static func httpTypes(_ name: String) -> TypeName { TypeName(swiftKeyPath: [Constants.Import.httpTypes, name]) }

    /// Returns the type name for the Date type.
    static var date: Self { .foundation("Date") }

    /// Returns the type name for the URL type.
    static var url: Self { .foundation("URL") }

    /// Returns the type name for the DecodingError type.
    static var decodingError: Self { .swift("DecodingError") }

    /// Returns the type name for the UndocumentedPayload type.
    static var undocumentedPayload: Self {
        .runtime(Constants.Operation.Output.undocumentedCaseAssociatedValueTypeName)
    }

    /// Returns the type name of generic JSON payload.
    static var valueContainer: TypeName { .runtime("OpenAPIValueContainer") }

    /// Returns the type name of an object of generic JSON payload.
    static var objectContainer: TypeName { .runtime("OpenAPIObjectContainer") }

    /// Returns the type name of an array of generic JSON payload.
    static var arrayContainer: TypeName { .runtime("OpenAPIArrayContainer") }

    /// Returns the type name for the request type.
    static var request: TypeName { .httpTypes("HTTPRequest") }

    /// Returns the type name for the response type.
    static var response: TypeName { .httpTypes("HTTPResponse") }

    /// Returns the type name for the HTTP fields type.
    static var httpFields: TypeName { .httpTypes("HTTPFields") }

    /// Returns the type name for the body type.
    static var body: TypeName { .runtime("HTTPBody") }

    /// Returns the type name for the body type.
    static var multipartBody: TypeName { .runtime("MultipartBody") }

    /// Returns the type name for the multipart typed part type.
    static var multipartPart: TypeName { .runtime("MultipartPart") }

    /// Returns the type name for the multipart dynamically typed part type.
    static var multipartDynamicallyNamedPart: TypeName { .runtime("MultipartDynamicallyNamedPart") }

    /// Returns the type name for the multipart raw part type.
    static var multipartRawPart: TypeName { .runtime("MultipartRawPart") }

    /// Returns the type name for the server request metadata type.
    static var serverRequestMetadata: TypeName { .runtime("ServerRequestMetadata") }

    /// Returns the type name for the copy-on-write box type.
    static var box: TypeName { .runtime("CopyOnWriteBox") }

    /// Returns the type name for the base64 wrapper.
    static var base64: TypeName { .runtime("Base64EncodedData") }
}
