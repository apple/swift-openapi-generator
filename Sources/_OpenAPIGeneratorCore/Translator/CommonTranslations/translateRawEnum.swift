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
import OrderedCollections

/// The backing type of a raw enum.
enum RawEnumBackingType {

    /// Backed by a `String`.
    case string

    /// Backed by an `Int`.
    case integer
}

/// The extracted enum value's identifier.
private enum EnumCaseID: Hashable, CustomStringConvertible {

    /// A string value.
    case string(String)

    /// An integer value.
    case integer(Int)

    var description: String {
        switch self {
        case .string(let value): return "\"\(value)\""
        case .integer(let value): return String(value)
        }
    }
}

/// A wrapper for the metadata about the raw enum case.
private struct EnumCase {

    /// Used for checking uniqueness.
    var id: EnumCaseID

    /// The raw Swift-safe name for the case.
    var caseName: String

    /// The literal value of the enum case.
    var literal: LiteralDescription
}

extension EnumCase: Equatable { static func == (lhs: EnumCase, rhs: EnumCase) -> Bool { lhs.id == rhs.id } }

extension EnumCase: Hashable { func hash(into hasher: inout Hasher) { hasher.combine(id) } }

extension FileTranslator {

    /// Returns a declaration of the specified raw value-based enum schema.
    /// - Parameters:
    ///   - backingType: The backing type of the enum.
    ///   - typeName: The name of the type to give to the declared enum.
    ///   - userDescription: A user-specified description from the OpenAPI
    ///   document.
    ///   - isNullable: Whether the enum schema is nullable.
    ///   - allowedValues: The enumerated allowed values.
    /// - Throws: A `GenericError` if a disallowed value is encountered.
    /// - Returns: A declaration of the specified raw value-based enum schema.
    func translateRawEnum(
        backingType: RawEnumBackingType,
        typeName: TypeName,
        userDescription: String?,
        isNullable: Bool,
        allowedValues: [AnyCodable]
    ) throws -> Declaration {
        var cases: OrderedSet<EnumCase> = []
        func addIfUnique(id: EnumCaseID, caseName: String) throws {
            let literal: LiteralDescription
            switch id {
            case .string(let string): literal = .string(string)
            case .integer(let int): literal = .int(int)
            }
            guard cases.append(.init(id: id, caseName: caseName, literal: literal)).inserted else {
                try diagnostics.emit(
                    .warning(
                        message: "Duplicate enum value, skipping",
                        context: ["id": "\(id)", "foundIn": typeName.description]
                    )
                )
                return
            }
        }
        for anyValue in allowedValues.map(\.value) {
            switch backingType {
            case .string:
                // In nullable enum schemas, empty strings are parsed as Void.
                // This is unlikely to be fixed, so handling that case here.
                // https://github.com/apple/swift-openapi-generator/issues/118
                if isNullable && anyValue is Void {
                    try addIfUnique(id: .string(""), caseName: context.safeNameGenerator.swiftMemberName(for: ""))
                } else {
                    guard let rawValue = anyValue as? String else {
                        throw GenericError(message: "Disallowed value for a string enum '\(typeName)': \(anyValue)")
                    }
                    let caseName = context.safeNameGenerator.swiftMemberName(for: rawValue)
                    try addIfUnique(id: .string(rawValue), caseName: caseName)
                }
            case .integer:
                let rawValue: Int
                if let intRawValue = anyValue as? Int {
                    rawValue = intRawValue
                } else if let stringRawValue = anyValue as? String, let intRawValue = Int(stringRawValue) {
                    rawValue = intRawValue
                } else {
                    throw GenericError(message: "Disallowed value for an integer enum '\(typeName)': \(anyValue)")
                }
                let caseName = rawValue < 0 ? "_n\(abs(rawValue))" : "_\(rawValue)"
                try addIfUnique(id: .integer(rawValue), caseName: caseName)
            }
        }
        let baseConformance: String
        switch backingType {
        case .string: baseConformance = Constants.RawEnum.baseConformanceString
        case .integer: baseConformance = Constants.RawEnum.baseConformanceInteger
        }
        let conformances = [baseConformance] + Constants.RawEnum.conformances
        return try translateRawRepresentableEnum(
            typeName: typeName,
            conformances: conformances,
            userDescription: userDescription,
            cases: cases.map { ($0.caseName, $0.literal) },
            unknownCaseName: nil,
            unknownCaseDescription: nil
        )
    }
}
