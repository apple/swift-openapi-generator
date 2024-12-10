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
import Foundation

/// A content type of a request, response, and other types.
///
/// Represents the serialization method of the payload and affects
/// the generated serialization code.
struct ContentType: Hashable {

    /// The category of a content type.
    ///
    /// This categorization helps the generator decide how to handle
    /// the content's raw body data.
    enum Category: Hashable {

        /// A content type for JSON.
        ///
        /// The bytes are provided to a JSON encoder or decoder.
        case json

        /// A content type for raw binary data.
        ///
        /// This case covers both explicit binary data content types, such
        /// as `application/octet-stream`, and content types that no further
        /// introspection is performed on, such as `image/png`.
        ///
        /// The bytes are not further processed, they are instead passed along
        /// either to the network (requests) or to the caller (responses).
        case binary

        /// A content type for x-www-form-urlencoded.
        ///
        /// The top level properties of a Codable data model are encoded
        /// as key-value pairs in the form:
        ///
        ///  `key1=value1&key2=value2`
        ///
        /// The type is encoded as a binary UTF-8 data packet.
        case urlEncodedForm

        /// A content type for multipart/form-data.
        ///
        /// The type is encoded as an async sequence of parts.
        case multipart

        /// Creates a category from the provided type and subtype.
        ///
        /// First checks if the provided content type is a JSON, then text,
        /// and uses binary if none of the two match.
        /// - Parameters:
        ///   - lowercasedType: The first component of the MIME type.
        ///   - lowercasedSubtype: The second component of the MIME type.
        fileprivate init(lowercasedType: String, lowercasedSubtype: String) {
            // https://json-schema.org/draft/2020-12/json-schema-core.html#section-4.2
            if (lowercasedType == "application" && lowercasedSubtype == "json") || lowercasedSubtype.hasSuffix("+json")
            {
                self = .json
            } else if lowercasedType == "application" && lowercasedSubtype == "x-www-form-urlencoded" {
                self = .urlEncodedForm
            } else if lowercasedType == "multipart" && lowercasedSubtype == "form-data" {
                self = .multipart
            } else {
                self = .binary
            }
        }

        /// The coding strategy appropriate for this content type.
        var codingStrategy: CodingStrategy {
            switch self {
            case .json: return .json
            case .binary: return .binary
            case .urlEncodedForm: return .urlEncodedForm
            case .multipart: return .multipart
            }
        }
    }

    /// The mapped content type category.
    var category: Category { Category(lowercasedType: lowercasedType, lowercasedSubtype: lowercasedSubtype) }

    /// The first component of the MIME type.
    ///
    /// Preserves the casing from the input, do not use this
    /// for equality comparisons, use `lowercasedType` instead.
    let originallyCasedType: String

    /// The first component of the MIME type, as a lowercase string.
    ///
    /// The raw value in its original casing is only provided by `rawTypeAndSubtype`.
    var lowercasedType: String { originallyCasedType.lowercased() }

    /// The second component of the MIME type.
    ///
    /// Preserves the casing from the input, do not use this
    /// for equality comparisons, use `lowercasedSubtype` instead.
    let originallyCasedSubtype: String

    /// The second component of the MIME type, as a lowercase string.
    ///
    /// The raw value in its original casing is only provided by `originallyCasedTypeAndSubtype`.
    var lowercasedSubtype: String { originallyCasedSubtype.lowercased() }

    /// The parameter key-value pairs.
    ///
    /// Preserves the casing from the input, do not use this
    /// for equality comparisons, use `lowercasedParameterPairs` instead.
    let originallyCasedParameterPairs: [String]

    /// The parameter key-value pairs, lowercased.
    ///
    /// The raw value in its original casing is only provided by `originallyCasedParameterPairs`.
    var lowercasedParameterPairs: [String] { originallyCasedParameterPairs.map { $0.lowercased() } }

    /// The parameters string.
    var originallyCasedParametersString: String { originallyCasedParameterPairs.map { "; \($0)" }.joined() }

    /// The parameters string, lowercased.
    var lowercasedParametersString: String { originallyCasedParametersString.lowercased() }

    /// The type, subtype, and parameters components combined.
    var originallyCasedTypeSubtypeAndParameters: String {
        originallyCasedTypeAndSubtype + originallyCasedParametersString
    }

    /// The type, subtype, and parameters components combined and lowercased.
    var lowercasedTypeSubtypeAndParameters: String { originallyCasedTypeSubtypeAndParameters.lowercased() }

    /// Creates a new content type by parsing the specified MIME type.
    /// - Parameter string: A MIME type, for example "application/json". Must
    ///   not be empty.
    /// - Throws: If a malformed content type string is encountered.
    init(string: String) throws {
        struct InvalidContentTypeString: Error, LocalizedError, CustomStringConvertible {
            var string: String
            var description: String {
                "Invalid content type string: '\(string)', must have 2 components separated by a slash."
            }
            var errorDescription: String? { description }
        }
        guard !string.isEmpty else { throw InvalidContentTypeString(string: "") }
        var semiComponents = string.split(separator: ";")
        let typeAndSubtypeComponent = semiComponents.removeFirst()
        self.originallyCasedParameterPairs = semiComponents.map { component in
            component.split(separator: "=").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: "=")
        }
        let rawTypeAndSubtype = typeAndSubtypeComponent.trimmingCharacters(in: .whitespaces)
        let typeAndSubtype = rawTypeAndSubtype.split(separator: "/").map(String.init)
        guard typeAndSubtype.count == 2 else { throw InvalidContentTypeString(string: rawTypeAndSubtype) }
        self.originallyCasedType = typeAndSubtype[0]
        self.originallyCasedSubtype = typeAndSubtype[1]
    }

    /// Returns the type and subtype as a "<type>/<subtype>" string.
    ///
    /// Respects the original casing provided as input.
    var originallyCasedTypeAndSubtype: String { "\(originallyCasedType)/\(originallyCasedSubtype)" }

    /// Returns the type and subtype as a "<type>/<subtype>" string.
    ///
    /// Lowercased to ease case-insensitive comparisons.
    var lowercasedTypeAndSubtype: String { "\(lowercasedType)/\(lowercasedSubtype)" }

    /// Returns the type, subtype and parameters (if present) as a "<type>\/<subtype>[;<param>...]" string.
    ///
    /// Lowercased to ease case-insensitive comparisons, and escaped to show
    /// that the slash between type and subtype is not a path separator.
    var lowercasedTypeSubtypeAndParametersWithEscape: String {
        "\(lowercasedType)\\/\(lowercasedSubtype)" + lowercasedParametersString
    }

    /// The header value used when sending a content-type header.
    var headerValueForSending: String {
        guard case .json = category else { return lowercasedTypeSubtypeAndParameters }
        // We always encode JSON using JSONEncoder which uses UTF-8.
        // Check if it's already present, if not, append it.
        guard !lowercasedParameterPairs.contains("charset=") else { return lowercasedTypeSubtypeAndParameters }
        return lowercasedTypeSubtypeAndParameters + "; charset=utf-8"
    }

    /// The header value used when validating a content-type header.
    ///
    /// This should be less strict, e.g. not require `charset`.
    var headerValueForValidation: String { lowercasedTypeSubtypeAndParameters }

    /// The coding strategy appropriate for this content type.
    var codingStrategy: CodingStrategy { category.codingStrategy }

    /// A Boolean value that indicates whether the content type
    /// is a type of JSON.
    var isJSON: Bool { category == .json }

    /// A Boolean value that indicates whether the content type
    /// is just binary data.
    var isBinary: Bool { category == .binary }

    /// A Boolean value that indicates whether the content type
    /// is a URL-encoded form.
    var isUrlEncodedForm: Bool { category == .urlEncodedForm }

    /// A Boolean value that indicates whether the content type
    /// is a multipart form.
    var isMultipart: Bool { category == .multipart }

    /// The content type `text/plain`.
    static var textPlain: Self { try! .init(string: "text/plain") }

    /// The content type `application/json`.
    static var applicationJSON: Self { try! .init(string: "application/json") }

    /// The content type `application/octet-stream`.
    static var applicationOctetStream: Self { try! .init(string: "application/octet-stream") }

    static func == (lhs: Self, rhs: Self) -> Bool {
        // MIME type equality is case-insensitive.
        lhs.lowercasedTypeAndSubtype == rhs.lowercasedTypeAndSubtype
    }

    func hash(into hasher: inout Hasher) { hasher.combine(lowercasedTypeAndSubtype) }
}

extension OpenAPI.ContentType {

    /// Returns the content type wrapped in the generator's representation
    /// of a content type, as opposed to the one from OpenAPIKit.
    var asGeneratorContentType: ContentType { get throws { try ContentType(string: rawValue) } }
}
