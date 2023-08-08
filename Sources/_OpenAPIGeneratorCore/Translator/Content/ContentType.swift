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

        /// Creates a category from the provided type and subtype.
        ///
        /// First checks if the provided content type is a JSON, then text,
        /// and uses binary if none of the two match.
        /// - Parameters:
        ///   - type: The first component of the MIME type.
        ///   - subtype: The second component of the MIME type.
        init(type: String, subtype: String) {
            let lowercasedType = type.lowercased()
            let lowercasedSubtype = subtype.lowercased()

            // https://json-schema.org/draft/2020-12/json-schema-core.html#section-4.2
            if (lowercasedType == "application" && lowercasedSubtype == "json") || lowercasedSubtype.hasSuffix("+json")
            {
                self = .json
            } else if lowercasedType == "text" {
                self = .text
            } else {
                self = .binary
            }
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

    /// The mapped content type category.
    var category: Category {
        Category(type: type, subtype: subtype)
    }

    /// The first component of the MIME type.
    private let type: String

    /// The first component of the MIME type, as a lowercase string.
    ///
    /// The raw value in its original casing is only provided by `rawTypeAndSubtype`.
    var lowercasedType: String {
        type.lowercased()
    }

    /// The second component of the MIME type.
    private let subtype: String

    /// The second component of the MIME type, as a lowercase string.
    ///
    /// The raw value in its original casing is only provided by `originallyCasedTypeAndSubtype`.
    var lowercasedSubtype: String {
        subtype.lowercased()
    }

    /// Creates a new content type by parsing the specified MIME type.
    /// - Parameter rawValue: A MIME type, for example "application/json". Must
    ///   not be empty.
    init(_ rawValue: String) {
        precondition(!rawValue.isEmpty, "rawValue of a ContentType cannot be empty.")
        let rawTypeAndSubtype =
            rawValue
            .split(separator: ";")[0]
            .trimmingCharacters(in: .whitespaces)
        let typeAndSubtype =
            rawTypeAndSubtype
            .split(separator: "/")
            .map(String.init)
        precondition(
            typeAndSubtype.count == 2,
            "Invalid ContentType string, must have 2 components separated by a slash."
        )
        self.type = typeAndSubtype[0]
        self.subtype = typeAndSubtype[1]
    }

    /// Returns the type and subtype as a "<type>/<subtype>" string.
    ///
    /// Respects the original casing provided as input.
    var originallyCasedTypeAndSubtype: String {
        "\(type)/\(subtype)"
    }

    /// Returns the type and subtype as a "<type>/<subtype>" string.
    ///
    /// Lowercased to ease case-insensitive comparisons.
    var lowercasedTypeAndSubtype: String {
        "\(lowercasedType)/\(lowercasedSubtype)"
    }

    /// The header value used when sending a content-type header.
    var headerValueForSending: String {
        guard case .json = category else {
            return lowercasedTypeAndSubtype
        }
        // We always encode JSON using JSONEncoder which uses UTF-8.
        return lowercasedTypeAndSubtype + "; charset=utf-8"
    }

    /// The header value used when validating a content-type header.
    ///
    /// This should be less strict, e.g. not require `charset`.
    var headerValueForValidation: String {
        lowercasedTypeAndSubtype
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

    static func == (lhs: Self, rhs: Self) -> Bool {
        // MIME type equality is case-insensitive.
        lhs.lowercasedTypeAndSubtype == rhs.lowercasedTypeAndSubtype
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(lowercasedTypeAndSubtype)
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
