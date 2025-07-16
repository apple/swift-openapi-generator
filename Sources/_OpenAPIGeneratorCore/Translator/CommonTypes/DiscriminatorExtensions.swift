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
struct OneOfMappedType: Hashable {

    /// The raw names expected in the discriminator for this type.
    ///
    /// Usually matches the raw name from the OpenAPI document, either the last
    /// path component of the `#/components/schemas/Foo` name, or the raw key
    /// value in a discriminator's mapping. That's why it's an array.
    ///
    /// Not automatically safe to be used as a Swift identifier.
    ///
    /// Never empty.
    let rawNames: [String]

    /// The type name for this child schema.
    let typeName: TypeName

    /// The JSON reference.
    let reference: JSONReference<JSONSchema>

    /// Creates a new type.
    /// - Parameters:
    ///   - rawNames: The raw names to match for during decoding.
    ///   - typeName: The type name.
    ///   - reference: JSONReference<JSONSchema>.InternalReference.
    init(rawNames: [String], typeName: TypeName, reference: JSONReference<JSONSchema>) {
        precondition(!rawNames.isEmpty, "Must specify at least one raw name")
        self.rawNames = rawNames
        self.typeName = typeName
        self.reference = reference
    }

    /// An error thrown during oneOf type mapping.
    enum MappingError: Swift.Error, LocalizedError, CustomStringConvertible {

        /// The value in the mapping is not a valid JSON reference.
        case invalidMappingValue(String)

        /// The reference isn't a valid `#/components/schemas/` reference.
        case invalidReference(String)

        var description: String {
            switch self {
            case .invalidMappingValue(let value):
                return "Invalid discriminator.mapping value: '\(value)', must be an internal JSON reference."
            case .invalidReference(let reference): return "Invalid reference: '\(reference)'."
            }
        }

        var errorDescription: String? { description }
    }
}

extension FileTranslator {

    /// The case name, safe for Swift code.
    ///
    /// Does not include the leading dot.
    ///
    /// Derived from the mapping key, or the type name, as the last path
    /// component.
    /// - Parameter type: The `OneOfMappedType` for which to determine the case name.
    /// - Returns: A string representing the safe Swift name for the specified `OneOfMappedType`.
    func safeSwiftNameForOneOfMappedCase(_ type: OneOfMappedType) -> String {
        context.safeNameGenerator.swiftMemberName(for: type.rawNames[0])
    }
}

extension OpenAPI.Discriminator {

    /// Returns all the types discovered both in the provided list of schemas
    /// and in the optional mapping.
    ///
    /// ## Background
    /// The list of cases isn't dependent only on the list of subschemas, but
    /// also on the optional discriminator.mapping property, which can
    /// actually map from multiple keys to the same value.
    /// At the same time, the mapping doesn't have to mention all the
    /// subschemas, in which case the default behavior (use the JSON
    /// path of the schema) is used.
    ///
    /// This means that we have two sources of cases:
    ///   - list of subschemas
    ///   - discriminator.mapping
    ///
    /// And the final list of cases is a union of these two sources.
    /// Regarding order, somewhat arbitrarily, let's put the cases from
    /// the mapping first, and all the other ones second.
    /// - Parameters:
    ///   - schemas: The subschemas of the oneOf with this discriminator.
    ///   - typeAssigner: The current type assigner.
    /// - Throws: An error if there's an issue while discovering the types.
    /// - Returns: The list of discovered types.
    func allTypes(schemas: [JSONReference<JSONSchema>], typeAssigner: TypeAssigner) throws -> [OneOfMappedType] {
        let mapped = try pairsFromMapping(typeAssigner: typeAssigner)
        let mappedTypes = Set(mapped.map(\.typeName))
        var merged = mapped
        let subschemas = try pairsFromReferences(schemas, typeAssigner: typeAssigner)
        // Now, we only include a type here if it's not already mentioned
        // by the mapping.
        for subschema in subschemas {
            if mappedTypes.contains(subschema.typeName) { continue }
            merged.append(subschema)
        }
        return merged
    }

    /// Returns the mapped types provided by the discriminator's mapping.
    /// - Parameter typeAssigner: The current type assigner, used to assign
    ///   a Swift type to the found JSON reference.
    /// - Throws: An error if there's an issue while extracting mapped types from the mapping.
    /// - Returns: An array of found mapped types, but might also be empty.
    private func pairsFromMapping(typeAssigner: TypeAssigner) throws -> [OneOfMappedType] {
        guard let mapping else { return [] }
        // Mapping is a Swift dictionary, so order isn't defined. To produce
        // stable output, sort by keys here before going through the pairs.
        let pairs = mapping.sorted(by: { a, b in a.key.localizedCaseInsensitiveCompare(b.key) == .orderedAscending })
        return try pairs.map { key, value in
            // If a discriminator was specified, we know all the subschemas
            // are references to objectish schemas. The reference is all we
            // need to derive the Swift name.
            // The value in the mapping is the raw JSON reference.
            guard let ref = JSONReference<JSONSchema>.InternalReference(rawValue: value) else {
                throw OneOfMappedType.MappingError.invalidMappingValue(value)
            }
            let typeName = try typeAssigner.typeName(for: ref)
            return .init(rawNames: [key], typeName: typeName, reference: .internal(ref))
        }
    }

    /// Returns the mapped types for the provided subschema.
    /// - Throws: When an inconsistency is detected.
    private func pairsFromReferences(_ refs: [JSONReference<JSONSchema>], typeAssigner: TypeAssigner) throws
        -> [OneOfMappedType]
    {
        try refs.map { ref in
            guard case let .internal(internalRef) = ref else {
                throw JSONReferenceParsingError.externalPathsUnsupported(ref.absoluteString)
            }
            // Check both for "Foo" and "#/components/schemas/Foo", as both
            // are supported.
            let jsonPath = internalRef.rawValue
            guard let name = internalRef.name else { throw OneOfMappedType.MappingError.invalidReference(jsonPath) }
            let typeName = try typeAssigner.typeName(for: internalRef)
            return OneOfMappedType(rawNames: [name, jsonPath], typeName: typeName, reference: ref)
        }
    }
}
