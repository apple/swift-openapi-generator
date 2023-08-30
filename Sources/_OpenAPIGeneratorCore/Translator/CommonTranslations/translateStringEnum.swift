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

extension FileTranslator {

    /// Returns a declaration of the specified string-based enum schema.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared enum.
    ///   - userDescription: A user-specified description from the OpenAPI
    ///   document.
    ///   - isNullable: Whether the enum schema is nullable.
    ///   - allowedValues: The enumerated allowed values.
    func translateStringEnum(
        typeName: TypeName,
        userDescription: String?,
        isNullable: Bool,
        allowedValues: [AnyCodable]
    ) throws -> Declaration {
        let rawValues = try allowedValues.map(\.value)
            .map { anyValue in
                // In nullable enum schemas, empty strings are parsed as Void.
                // This is unlikely to be fixed, so handling that case here.
                // https://github.com/apple/swift-openapi-generator/issues/118
                if isNullable && anyValue is Void {
                    return ""
                }
                guard let string = anyValue as? String else {
                    throw GenericError(message: "Disallowed value for a string enum '\(typeName)': \(anyValue)")
                }
                return string
            }
        let cases = rawValues.map { rawValue in
            let caseName = swiftSafeName(for: rawValue)
            return (caseName, rawValue)
        }
        let conformances = [Constants.StringEnum.baseConformance] + Constants.StringEnum.conformances
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
