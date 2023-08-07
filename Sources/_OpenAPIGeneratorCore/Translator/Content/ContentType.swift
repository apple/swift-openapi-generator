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
struct ContentType: Hashable {

    /// The category of a content type.
    enum Category: Hashable {

        /// A content type for JSON.
        case json

        /// A content type for any plain text.
        case text

        /// A content type for raw binary data.
        case binary

        /// Creates a category from the provided raw string.
        ///
        /// First checks if the provided content type is a JSON, then text,
        /// and uses binary if none of the two match.
        /// - Parameter rawValue: A string with the content type to create.
        init(rawValue: String) {
            // https://json-schema.org/draft/2020-12/json-schema-core.html#section-4.2
            if rawValue == "application/json" || rawValue.hasSuffix("+json") {
                self = .json
                return
            }
            if rawValue.hasPrefix("text/") {
                self = .text
                return
            }
            self = .binary
        }

        /// The coding strategy appropriate for this content type.
        var codingStrategy: CodingStrategy {
            switch self {
            case .json:
                return .json
            case .text:
                return .text
            case .binary:
                return .binary
            }
        }
    }

    /// The underlying raw content type string.
    private let rawValue: String

    /// The mapped content type category.
    let category: Category

    /// Creates a new content type by parsing the specified MIME type.
    /// - Parameter rawValue: A MIME type, for example "application/json".
    init(_ rawValue: String) {
        self.rawValue = rawValue
        self.category = Category(rawValue: rawValue)
    }

    /// Returns the original raw MIME type.
    var rawMIMEType: String {
        rawValue
    }

    /// The header value used when sending a content-type header.
    var headerValueForSending: String {
        guard case .json = category else {
            return rawValue
        }
        // We always encode JSON using JSONEncoder which uses UTF-8.
        return rawValue + "; charset=utf-8"
    }

    /// The header value used when validating a content-type header.
    ///
    /// This should be less strict, e.g. not require `charset`.
    var headerValueForValidation: String {
        rawValue
    }

    /// The coding strategy appropriate for this content type.
    var codingStrategy: CodingStrategy {
        category.codingStrategy
    }

    /// A Boolean value that indicates whether the content type
    /// is a type of JSON.
    var isJSON: Bool {
        category == .json
    }

    /// A Boolean value that indicates whether the content type
    /// is a type of plain text.
    var isText: Bool {
        category == .text
    }

    /// A Boolean value that indicates whether the content type
    /// is just binary data.
    var isBinary: Bool {
        category == .binary
    }
}

extension OpenAPI.ContentType {

    /// A Boolean value that indicates whether the content type
    /// is a type of JSON.
    var isJSON: Bool {
        asGeneratorContentType.isJSON
    }

    /// A Boolean value that indicates whether the content type
    /// is a type of plain text.
    var isText: Bool {
        asGeneratorContentType.isText
    }

    /// A Boolean value that indicates whether the content type
    /// is just binary data.
    var isBinary: Bool {
        asGeneratorContentType.isBinary
    }

    /// Returns the content type wrapped in the generator's representation
    /// of a content type, as opposed to the one from OpenAPIKit.
    var asGeneratorContentType: ContentType {
        ContentType(typeAndSubtype)
    }
}
