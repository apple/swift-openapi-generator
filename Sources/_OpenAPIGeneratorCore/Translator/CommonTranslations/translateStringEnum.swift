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

/// The backing type of a raw enum.
enum RawEnumBackingType {

    /// Backed by a `String`.
    case string

    /// Backed by an `Int`.
    case integer
}

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
        let cases: [(String, LiteralDescription)] = try allowedValues.map(\.value)
            .map { anyValue in
                switch backingType {
                case .string:
                    // In nullable enum schemas, empty strings are parsed as Void.
                    // This is unlikely to be fixed, so handling that case here.
                    // https://github.com/apple/swift-openapi-generator/issues/118
                    if isNullable && anyValue is Void { return (context.asSwiftSafeName(""), .string("")) }
                    guard let rawValue = anyValue as? String else {
                        throw GenericError(message: "Disallowed value for a string enum '\(typeName)': \(anyValue)")
                    }
                    let caseName = context.asSwiftSafeName(rawValue)
                    return (caseName, .string(rawValue))
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
                    return (caseName, .int(rawValue))
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
            cases: cases,
            unknownCaseName: nil,
            unknownCaseDescription: nil
        )
    }
}
