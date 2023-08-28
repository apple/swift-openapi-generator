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

/// A child schema of a oneOf with a discriminator.
///
/// Details: https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#fixed-fields-21
struct OneOfMappedType: Equatable {

    /// The raw name expected in the discriminator for this type.
    ///
    /// Usually matches the raw name from the OpenAPI document, either the last
    /// path component of the `#/components/schemas/Foo` name, or the raw key
    /// value in a discriminator's mapping.
    ///
    /// Not automatically safe to be used as a Swift identifier.
    var rawName: String

    /// The type name for this child schema.
    var typeName: TypeName

    /// The case name, safe for Swift code.
    ///
    /// Does not include the leading dot.
    ///
    /// Derived from the type name, as the last path component.
    var caseName: String {
        typeName.shortSwiftName
    }

    /// An error thrown during oneOf type mapping.
    enum MappingError: Swift.Error, LocalizedError, CustomStringConvertible {
        case nonUniqueMapping

        var description: String {
            switch self {
            case .nonUniqueMapping:
                return "In discriminator.mapping, found multiple keys for the same value."
            }
        }

        var errorDescription: String? {
            description
        }
    }
}

extension OpenAPI.Discriminator {

    /// Returns the mapped type for the provided child schema, taking the optional
    /// mapping into consideration.
    /// - Throws: When an inconsistency is detected.
    func mappedTypes(_ types: [TypeName]) throws -> [OneOfMappedType] {
        guard let mapping else {
            // Without a mapping, the raw name and case name are the same, which
            // is the short name of the type itself.
            return types.map { type in
                .init(
                    rawName: type.shortJSONName ?? type.shortSwiftName,
                    typeName: type
                )
            }
        }
        // Create a back-mapping, as we need to match the values with our
        // types, and find the manually defined raw key for it.
        // First ensure uniqueness of values, otherwise throw an error.
        if Set(mapping.values).count < mapping.values.count {
            throw OneOfMappedType.MappingError.nonUniqueMapping
        }
        let backMapping = Dictionary(
            uniqueKeysWithValues: mapping.map { ($1, $0) }
        )
        // If a type is found in the mapping, use the key as the raw value.
        // Otherwise, fall back to as if the mapping was not present for that
        // child schema.
        return types.map { type in
            let shortName = type.shortJSONName ?? type.shortSwiftName
            // Check both for "Foo" and "#/components/schemas/Foo", as both
            // are supported.
            let rawKey: String?
            if let rawName = backMapping[shortName] {
                rawKey = rawName
            } else if let jsonPath = type.fullyQualifiedJSONPath,
                let rawName = backMapping[jsonPath]
            {
                rawKey = rawName
            } else {
                rawKey = nil
            }
            return .init(
                rawName: rawKey ?? shortName,
                typeName: type
            )
        }
    }
}
