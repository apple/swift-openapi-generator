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

/// A type of an OpenAPI operation response: a specific HTTP status code,
/// a range of HTTP status codes, or default.
enum ResponseKind {

    /// A specific HTTP status code.
    case code(Int)

    /// A range of HTTP status codes.
    case range(RangeType)

    /// A default response.
    case `default`

    /// A range of HTTP status codes.
    enum RangeType {

        /// Informational responses.
        case _1XX

        /// Successful responses.
        case _2XX

        /// Redirection responses.
        case _3XX

        /// Client error responses.
        case _4XX

        /// Server error responses.
        case _5XX

        /// Creates a new range that matches the specified OpenAPI range.
        init(_ range: OpenAPI.Response.StatusCode.Range) {
            switch range {
            case .information: self = ._1XX
            case .success: self = ._2XX
            case .redirect: self = ._3XX
            case .clientError: self = ._4XX
            case .serverError: self = ._5XX
            }
        }

        /// A JSON path component for the range.
        var jsonPathComponent: String {
            switch self {
            case ._1XX: return "1XX"
            case ._2XX: return "2XX"
            case ._3XX: return "3XX"
            case ._4XX: return "4XX"
            case ._5XX: return "5XX"
            }
        }

        /// The lowest HTTP status code in the range.
        var lowerBound: Int {
            switch self {
            case ._1XX: return 100
            case ._2XX: return 200
            case ._3XX: return 300
            case ._4XX: return 400
            case ._5XX: return 500
            }
        }

        /// The highest HTTP status code in the range.
        var upperBound: Int { lowerBound + 99 }

        /// A human-readable name for the range.
        var prettyName: String {
            switch self {
            case ._1XX: return "informational"
            case ._2XX: return "successful"
            case ._3XX: return "redirection"
            case ._4XX: return "clientError"
            case ._5XX: return "serverError"
            }
        }
    }

    /// A Boolean value that indicates whether the response requires passing
    /// in the specific HTTP status code only known at runtime.
    ///
    /// Note that it might be counter-intuitive, but the code response kind
    /// doesn't require a status code passed around at runtime, as it
    /// unambiguously specifies an HTTP status code. Only the range and default
    /// responses require the generator to include a variable for the HTTP
    /// status code.
    ///
    /// - Returns: `true` for the range and default response, `false` for
    /// code responses.
    var wantsStatusCode: Bool { code == nil }

    /// A name of the response usable as a Swift identifier.
    var identifier: String {
        switch self {
        case .`default`: return "`default`"
        case .code(let code): return HTTPStatusCodes.safeName(for: code)
        case .range(let range): return range.prettyName
        }
    }

    /// A JSON path component for the response.
    var jsonPathComponent: String {
        switch self {
        case .`default`: return "default"
        case .code(let int): return "\(int)"
        case .range(let rangeType): return rangeType.jsonPathComponent
        }
    }

    /// A human-readable name for the response.
    var prettyName: String {
        switch self {
        case .`default`: return "default"
        case .code(let code): return HTTPStatusCodes.safeName(for: code)
        case .range(let range): return range.prettyName
        }
    }

    /// The concrete HTTP status code represented by the response.
    ///
    /// - Returns: An integer for code responses; nil for responses that
    /// represent multiple codes, such as a range or default.
    var code: Int? {
        switch self {
        case .`default`, .range: return nil
        case .code(let code): return code
        }
    }

    /// Returns a new type name that appends the response's Swift name to
    /// the specified parent type name.
    func typeName(in parent: TypeName) -> TypeName {
        parent.appending(swiftComponent: prettyName.uppercasingFirstLetter, jsonComponent: jsonPathComponent)
    }
}

extension ResponseKind: CustomStringConvertible { var description: String { prettyName } }

extension OpenAPI.Response.StatusCode.Code {

    /// Returns the matching OpenAPI response kind.
    var asKind: ResponseKind {
        switch self {
        case .`default`: return .`default`
        case .status(let code): return .code(code)
        case .range(let range): return .range(.init(range))
        }
    }
}
