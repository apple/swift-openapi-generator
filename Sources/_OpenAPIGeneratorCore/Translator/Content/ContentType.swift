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
import OpenAPIKit30

/// A content type of a request, response, and other types.
///
/// Represents the serialization method of the payload and affects
/// the generated serialization code.
enum ContentType: Hashable {

    /// A content type for JSON.
    case json(String)

    /// A content type for any plain text.
    case text(String)

    /// A content type for raw binary data.
    case binary(String)

    /// Creates a new content type by parsing the specified MIME type.
    /// - Parameter rawValue: A MIME type, for example "application/json".
    init?(_ rawValue: String) {
        if rawValue.hasPrefix("application/") && rawValue.hasSuffix("json") {
            self = .json(rawValue)
            return
        }
        if rawValue.hasPrefix("text/") {
            self = .text(rawValue)
            return
        }
        self = .binary(rawValue)
    }

    /// The header value used when sending a content-type header.
    var headerValueForSending: String {
        switch self {
        case .json(let string):
            // We always encode JSON using JSONEncoder which uses UTF-8.
            return string + "; charset=utf-8"
        case .text(let string):
            return string
        case .binary(let string):
            return string
        }
    }

    /// The header value used when validating a content-type header.
    ///
    /// This should be less strict, e.g. not require `charset`.
    var headerValueForValidation: String {
        switch self {
        case .json(let string):
            return string
        case .text(let string):
            return string
        case .binary(let string):
            return string
        }
    }

    /// An identifier used as the Payload.Content enum case name
    /// in generated code.
    var identifier: String {
        switch self {
        case .json:
            return "json"
        case .text:
            return "text"
        case .binary:
            return "binary"
        }
    }

    /// A Boolean value that indicates whether the content type
    /// is a type of JSON.
    var isJSON: Bool {
        if case .json = self {
            return true
        }
        return false
    }

    /// A Boolean value that indicates whether the content type
    /// is a type of plain text.
    var isText: Bool {
        if case .text = self {
            return true
        }
        return false
    }

    /// A Boolean value that indicates whether the content type
    /// is just binary data.
    var isBinary: Bool {
        if case .binary = self {
            return true
        }
        return false
    }

    /// Returns a new content type representing an octet stream.
    static var octetStream: Self {
        .binary("application/octet-stream")
    }

    /// Returns a new content type representing JSON.
    static var applicationJSON: Self {
        .json("application/json")
    }
}

extension OpenAPI.ContentType {

    /// Returns a new content type representing an octet stream.
    static let octetStream: Self = .other(ContentType.octetStream.headerValueForValidation)

    /// A Boolean value that indicates whether the content type
    /// is a type of JSON.
    var isJSON: Bool {
        guard let contentType = ContentType(typeAndSubtype) else {
            return false
        }
        return contentType.isJSON
    }

    /// A Boolean value that indicates whether the content type
    /// is a type of plain text.
    var isText: Bool {
        guard let contentType = ContentType(typeAndSubtype) else {
            return false
        }
        return contentType.isText
    }

    /// A Boolean value that indicates whether the content type
    /// is just binary data.
    var isBinary: Bool {
        guard let contentType = ContentType(typeAndSubtype) else {
            return false
        }
        return contentType.isBinary
    }
}
