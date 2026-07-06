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

    /// Returns a declaration of a typealias.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared typealias.
    ///   - userDescription: A user-specified description from the OpenAPI document.
    ///   - existingTypeUsage: The existing type the alias points to.
    ///   - defaultValue: An optional default value for the typealias.
    /// - Throws: An error if there is an issue during translation.
    /// - Returns: A declaration representing the translated typealias.
    func translateTypealias(
        named typeName: TypeName,
        userDescription: String?,
        to existingTypeUsage: TypeUsage,
        defaultValue: AnyCodable?
    ) throws -> [Declaration] {
        let typealiasDescription = TypealiasDescription(
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            existingType: .init(existingTypeUsage.withOptional(false))
        )
        let typealiasComment: Comment? = typeName.docCommentWithUserDescription(userDescription)

        var declarations: [Declaration] = [.commentable(typealiasComment, .typealias(typealiasDescription))]

        if let defaultValue, let literalDescription = convertValueToLiteralDescription(defaultValue.value) {
            let defaultDecl: Declaration = .variable(
                accessModifier: config.access,
                isStatic: true,
                kind: .let,
                left: "`default`",
                type: .init(existingTypeUsage.withOptional(false)),
                right: .literal(literalDescription)
            )
            declarations.append(defaultDecl)
        }

        return declarations
    }

    /// Converts a given value to a `LiteralDescription`.
    ///
    /// - Parameter value: The value to be converted.
    /// - Returns: A `LiteralDescription` representing the value, or `nil` if the value cannot be converted.
    func convertValueToLiteralDescription(_ value: Any) -> LiteralDescription? {
        switch value {
        case let stringValue as String: return .string(stringValue)
        case let intValue as Int: return .int(intValue)
        case let boolValue as Bool: return .bool(boolValue)
        case let doubleValue as Double: return .double(doubleValue)
        case let arrayValue as [Any]:
            let arrayExpressions = arrayValue.compactMap { element -> Expression? in
                convertValueToLiteralDescription(element).map { .literal($0) }
            }
            return .array(arrayExpressions)
        default: return nil
        }
    }
}
