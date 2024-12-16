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

extension FileTranslator {

    // MARK: - Struct encoder and decoder

    /// Returns a declaration of a custom decoder initializer.
    /// - Parameters:
    ///   - strategy: The strategy of the requested Codable implementation.
    ///   - properties: The properties of the structure.
    /// - Returns: A declaration; nil if the decoder should be synthesized.
    func translateStructBlueprintDecoder(
        strategy: StructBlueprint.OpenAPICodableStrategy,
        properties: [PropertyBlueprint]
    ) -> Declaration? {
        let knownKeys = properties.map(\.originalName)
        let knownKeysFunctionArg = FunctionArgumentDescription(
            label: "knownKeys",
            expression: .literal(.array(knownKeys.map { .literal($0) }))
        )
        switch strategy {
        case .synthesized: return nil
        case .enforcingNoAdditionalProperties:
            return translateStructBlueprintCustomDecoder(
                properties: properties,
                trailingCodeBlocks: [
                    .expression(
                        .try(
                            .identifierPattern("decoder").dot("ensureNoAdditionalProperties")
                                .call([knownKeysFunctionArg])
                        )
                    )
                ]
            )
        case .allowingAdditionalProperties:
            return translateStructBlueprintCustomDecoder(
                properties: properties,
                trailingCodeBlocks: [
                    .expression(
                        .assignment(
                            left: .identifierPattern(Constants.AdditionalProperties.variableName),
                            right: .try(
                                .identifierPattern("decoder").dot("decodeAdditionalProperties")
                                    .call([knownKeysFunctionArg])
                            )
                        )
                    )
                ]
            )
        case .allOf(propertiesIsKeyValuePairSchema: let isKeyValuePairs):
            return translateStructBlueprintAllOfDecoder(properties: Array(zip(properties, isKeyValuePairs)))
        case .anyOf(propertiesIsKeyValuePairSchema: let isKeyValuePairs):
            return translateStructBlueprintAnyOfDecoder(properties: Array(zip(properties, isKeyValuePairs)))
        }
    }

    /// Returns a declaration of a custom encoder function.
    /// - Parameters:
    ///   - strategy: The strategy of the requested Codable implementation.
    ///   - properties: The properties of the structure.
    /// - Returns: A declaration; nil if the encoder should be synthesized.
    func translateStructBlueprintEncoder(
        strategy: StructBlueprint.OpenAPICodableStrategy,
        properties: [PropertyBlueprint]
    ) -> Declaration? {
        switch strategy {
        case .synthesized, .enforcingNoAdditionalProperties: return nil
        case .allowingAdditionalProperties:
            return translateStructBlueprintCustomEncoder(
                properties: properties,
                trailingCodeBlocks: [
                    .expression(
                        .try(
                            .identifierPattern("encoder").dot("encodeAdditionalProperties")
                                .call([
                                    .init(
                                        label: nil,
                                        expression: .identifierPattern(Constants.AdditionalProperties.variableName)
                                    )
                                ])
                        )
                    )
                ]
            )
        case .allOf(propertiesIsKeyValuePairSchema: let isKeyValuePairs):
            return translateStructBlueprintAllOfEncoder(properties: Array(zip(properties, isKeyValuePairs)))
        case .anyOf(propertiesIsKeyValuePairSchema: let isKeyValuePairs):
            return translateStructBlueprintAnyOfEncoder(properties: Array(zip(properties, isKeyValuePairs)))
        }
    }

    // MARK: - Custom encoder and decoder

    /// Returns a declaration of a decoder implementation.
    /// - Parameters:
    ///   - properties: The properties to decode.
    ///   - trailingCodeBlocks: Additional code blocks to add at the end of
    ///   the body of the decoder initializer.
    /// - Returns: A declaration representing the custom decoder implementation.
    func translateStructBlueprintCustomDecoder(properties: [PropertyBlueprint], trailingCodeBlocks: [CodeBlock] = [])
        -> Declaration
    {
        let containerVarDecl: Declaration = .decoderContainerOfKeysVar()
        let assignExprs: [Expression] = properties.map { property in
            let typeUsage = property.typeUsage
            return .assignment(
                left: .selfDot(property.swiftSafeName),
                right: .try(
                    .identifierPattern("container").dot("decode\(typeUsage.isOptional ? "IfPresent" : "")")
                        .call([
                            .init(label: nil, expression: .identifierType(typeUsage.withOptional(false)).dot("self")),
                            .init(label: "forKey", expression: .dot(property.swiftSafeName)),
                        ])
                )
            )
        }
        let decodingCodeBlocks: [CodeBlock]
        if !properties.isEmpty {
            decodingCodeBlocks = [.declaration(containerVarDecl)] + assignExprs.map { .expression($0) }
        } else {
            decodingCodeBlocks = []
        }
        return decoderInitializer(body: decodingCodeBlocks + trailingCodeBlocks)
    }

    /// Returns a declaration of an encoder implementation.
    /// - Parameters:
    ///   - properties: The properties to encode.
    ///   - trailingCodeBlocks: Additional code blocks to add at the end of
    ///   the body of the encoder initializer.
    /// - Returns: A `Declaration` representing the custom decoder implementation.
    func translateStructBlueprintCustomEncoder(properties: [PropertyBlueprint], trailingCodeBlocks: [CodeBlock] = [])
        -> Declaration
    {
        let containerVarDecl: Declaration = .variable(
            kind: .var,
            left: "container",
            right: .identifierPattern("encoder").dot("container")
                .call([.init(label: "keyedBy", expression: .identifierType(.member("CodingKeys")).dot("self"))])
        )
        let encodeExprs: [Expression] = properties.map { property in
            .try(
                .identifierPattern("container").dot("encode\(property.typeUsage.isOptional ? "IfPresent" : "")")
                    .call([
                        .init(label: nil, expression: .selfDot(property.swiftSafeName)),
                        .init(label: "forKey", expression: .dot(property.swiftSafeName)),
                    ])
            )
        }
        let encodingCodeBlocks: [CodeBlock]
        if !properties.isEmpty {
            encodingCodeBlocks = [.declaration(containerVarDecl)] + encodeExprs.map { .expression($0) }
        } else {
            encodingCodeBlocks = []
        }
        return encoderFunction(body: encodingCodeBlocks + trailingCodeBlocks)
    }

    // MARK: - AllOf encoder and decoder

    /// Returns a declaration of an allOf decoder implementation.
    /// - Parameter properties: The properties to decode.
    /// - Returns: A `Declaration` representing the `allOf` decoder implementation.
    func translateStructBlueprintAllOfDecoder(properties: [(property: PropertyBlueprint, isKeyValuePair: Bool)])
        -> Declaration
    {
        let assignExprs: [Expression] = properties.map { property, isKeyValuePair in
            let decoderExpr: Expression =
                isKeyValuePair ? .initFromDecoderExpr() : .decodeFromSingleValueContainerExpr()
            return .assignment(left: .selfDot(property.swiftSafeName), right: .try(decoderExpr))
        }
        return decoderInitializer(body: assignExprs.map { .expression($0) })
    }

    /// Returns a declaration of an allOf encoder implementation.
    /// - Parameter properties: The properties to encode.
    /// - Returns: A `Declaration` representing the `allOf` encoder implementation.
    func translateStructBlueprintAllOfEncoder(properties: [(property: PropertyBlueprint, isKeyValuePair: Bool)])
        -> Declaration
    {
        let exprs: [Expression]
        if let firstSingleValue = properties.first(where: { !$0.isKeyValuePair }) {
            let expr: Expression = .selfDot(firstSingleValue.property.swiftSafeName)
                .encodeToSingleValueContainerExpr(gracefully: false)
            exprs = [expr]
        } else {
            exprs = properties.filter(\.isKeyValuePair).map { .selfDot($0.property.swiftSafeName).encodeExpr() }
        }
        return encoderFunction(body: exprs.map { .expression($0) })
    }

    // MARK: - AnyOf encoder and decoder

    /// Returns a declaration of an anyOf decoder implementation.
    /// - Parameter properties: The properties to be decoded using the `AnyOf` schema.
    /// - Returns: A `Declaration` representing the `anyOf` decoder implementation.
    func translateStructBlueprintAnyOfDecoder(properties: [(property: PropertyBlueprint, isKeyValuePair: Bool)])
        -> Declaration
    {
        let errorArrayDecl: Declaration = .createErrorArrayDecl()
        let assignBlocks: [CodeBlock] = properties.map { (property, isKeyValuePair) in
            let decoderExpr: Expression =
                isKeyValuePair ? .initFromDecoderExpr() : .decodeFromSingleValueContainerExpr()
            let assignExpr: Expression = .assignment(left: .selfDot(property.swiftSafeName), right: .try(decoderExpr))
            return .expression(assignExpr.wrapInDoCatchAppendArrayExpr())
        }
        let atLeastOneNotNilCheckExpr: Expression = .try(
            .identifierType(TypeName.decodingError).dot("verifyAtLeastOneSchemaIsNotNil")
                .call([
                    .init(
                        label: nil,
                        expression: .literal(.array(properties.map { .selfDot($0.property.swiftSafeName) }))
                    ), .init(label: "type", expression: .identifierPattern("Self").dot("self")),
                    .init(label: "codingPath", expression: .identifierPattern("decoder").dot("codingPath")),
                    .init(label: "errors", expression: .identifierPattern("errors")),
                ])
        )
        return decoderInitializer(
            body: [.declaration(errorArrayDecl)] + assignBlocks + [.expression(atLeastOneNotNilCheckExpr)]
        )
    }

    /// Returns a declaration of an anyOf encoder implementation.
    /// - Parameter properties: The properties to be encoded using the `AnyOf` schema.
    /// - Returns: A `Declaration` representing the `AnyOf` encoder implementation.
    func translateStructBlueprintAnyOfEncoder(properties: [(property: PropertyBlueprint, isKeyValuePair: Bool)])
        -> Declaration
    {
        let singleValueNames = properties.filter { !$0.isKeyValuePair }.map(\.property.swiftSafeName)
        let encodeSingleValuesExpr: Expression? =
            singleValueNames.isEmpty
            ? nil
            : .try(
                .identifierPattern("encoder").dot("encodeFirstNonNilValueToSingleValueContainer")
                    .call([.init(label: nil, expression: .literal(.array(singleValueNames.map { .selfDot($0) })))])
            )
        let encodeExprs: [Expression] =
            (encodeSingleValuesExpr.flatMap { [$0] } ?? [])
            + properties.filter { $0.isKeyValuePair }.map(\.property)
            .map { property in .selfDot(property.swiftSafeName).optionallyChained().encodeExpr() }
        return encoderFunction(body: encodeExprs.map { .expression($0) })
    }

    // MARK: - OneOf encoder and decoder

    /// Returns a declaration of a oneOf without discriminator decoder implementation.
    /// - Parameter cases: The names of the cases to be decoded.
    /// - Returns: A `Declaration` representing the `OneOf` decoder implementation.
    func translateOneOfWithoutDiscriminatorDecoder(cases: [(name: String, isKeyValuePair: Bool)]) -> Declaration {
        let errorArrayDecl: Declaration = .createErrorArrayDecl()
        let assignExprs: [Expression] = cases.map { (caseName, isKeyValuePair) in
            let decoderExpr: Expression =
                isKeyValuePair ? .initFromDecoderExpr() : .decodeFromSingleValueContainerExpr()
            let body: [CodeBlock] = [
                .expression(
                    .assignment(
                        left: .identifierPattern("self"),
                        right: .dot(caseName).call([.init(label: nil, expression: .try(decoderExpr))])
                    )
                ), .expression(.return()),
            ]
            return body.wrapInDoCatchAppendArrayExpr()
        }
        let otherExprs: [CodeBlock] = [.expression(translateOneOfDecoderThrowOnNoCaseDecodedExpr())]
        return decoderInitializer(
            body: [.declaration(errorArrayDecl)] + (assignExprs).map { .expression($0) } + otherExprs
        )
    }

    /// Returns an expression that throws an error when a oneOf discriminator
    /// failed to match any known cases.
    func translateOneOfDecoderThrowOnUnknownExpr(discriminatorSwiftName: String) -> Expression {
        .unaryKeyword(
            kind: .throw,
            expression: .identifierType(TypeName.decodingError).dot("unknownOneOfDiscriminator")
                .call([
                    .init(
                        label: "discriminatorKey",
                        expression: .identifierPattern(Constants.Codable.codingKeysName).dot(discriminatorSwiftName)
                    ), .init(label: "discriminatorValue", expression: .identifierPattern("discriminator")),
                    .init(label: "codingPath", expression: .identifierPattern("decoder").dot("codingPath")),
                ])
        )
    }
    /// Returns an expression that throws an error when a oneOf failed
    /// to match any documented cases.
    func translateOneOfDecoderThrowOnNoCaseDecodedExpr() -> Expression {
        .unaryKeyword(
            kind: .throw,
            expression: .identifierType(TypeName.decodingError).dot("failedToDecodeOneOfSchema")
                .call([
                    .init(label: "type", expression: .identifierPattern("Self").dot("self")),
                    .init(label: "codingPath", expression: .identifierPattern("decoder").dot("codingPath")),
                    .init(label: "errors", expression: .identifierPattern("errors")),
                ])
        )
    }
    /// Returns a declaration of a oneOf with a discriminator decoder implementation.
    /// - Parameters:
    ///   - discriminatorName: The name of the discriminator property used for case selection.
    ///   - cases: The cases to decode, first element is the raw string to check for, the second
    ///     element is the case name (without the leading dot).
    /// - Returns: A `Declaration` representing the `oneOf` decoder implementation.
    func translateOneOfWithDiscriminatorDecoder(
        discriminatorName: String,
        cases: [(caseName: String, rawNames: [String])]
    ) -> Declaration {
        let cases: [SwitchCaseDescription] = cases.map { caseName, rawNames in
            .init(
                kind: .multiCase(rawNames.map { .literal($0) }),
                body: [
                    .expression(
                        .assignment(
                            left: .identifierPattern("self"),
                            right: .dot(caseName).call([.init(label: nil, expression: .try(.initFromDecoderExpr()))])
                        )
                    )
                ]
            )
        }
        let otherExprs: [CodeBlock] = [
            .expression(translateOneOfDecoderThrowOnUnknownExpr(discriminatorSwiftName: discriminatorName))
        ]
        let body: [CodeBlock] = [
            .declaration(.decoderContainerOfKeysVar()),
            .declaration(
                .variable(
                    kind: .let,
                    left: Constants.OneOf.discriminatorName,
                    right: .try(
                        .identifierPattern("container").dot("decode")
                            .call([
                                .init(label: nil, expression: .identifierType(TypeName.string).dot("self")),
                                .init(label: "forKey", expression: .dot(discriminatorName)),
                            ])
                    )
                )
            ),
            .expression(
                .switch(
                    switchedExpression: .identifierPattern(Constants.OneOf.discriminatorName),
                    cases: cases + [.init(kind: .default, body: otherExprs)]
                )
            ),
        ]
        return decoderInitializer(body: body)
    }

    /// Returns a declaration of a oneOf encoder implementation.
    /// - Parameter cases: The case names to be encoded, including the special case for undocumented cases.
    /// - Returns: A `Declaration` representing the `OneOf` encoder implementation.
    func translateOneOfEncoder(cases: [(name: String, isKeyValuePair: Bool)]) -> Declaration {
        let switchExpr: Expression = .switch(
            switchedExpression: .identifierPattern("self"),
            cases: cases.map { caseName, isKeyValuePair in
                let makeEncodeExpr: (Expression, Bool) -> Expression = { expr, isKeyValuePair in
                    if isKeyValuePair {
                        return expr.encodeExpr()
                    } else {
                        return expr.encodeToSingleValueContainerExpr(gracefully: false)
                    }
                }
                return .init(
                    kind: .case(.dot(caseName), ["value"]),
                    body: [.expression(makeEncodeExpr(.identifierPattern("value"), isKeyValuePair))]
                )
            }
        )
        return encoderFunction(body: [.expression(switchExpr)])
    }
}

// MARK: - Utilities

fileprivate extension Expression {
    /// Returns a new expression that calls the encode method on the current
    /// expression.
    ///
    /// Assumes the existence of an "encoder" variable in the current scope.
    /// - Returns: An expression representing the encoding of the current value using the "encoder" variable.
    func encodeExpr() -> Expression {
        .try(self.dot("encode").call([.init(label: "to", expression: .identifierPattern("encoder"))]))
    }

    /// Returns a new expression that calls the encode method on the current
    /// expression for non-key-value pair schema values.
    ///
    /// Assumes the existence of an "encoder" variable in the current scope.
    /// - Parameter gracefully: A Boolean value indicating whether the graceful
    ///   variant of the expression is used.
    /// - Returns: An Expression representing the result of encoding the current expression.
    func encodeToSingleValueContainerExpr(gracefully: Bool) -> Expression {
        .try(
            .identifierPattern("encoder").dot("encodeToSingleValueContainer\(gracefully ? "Gracefully" : "")")
                .call([.init(label: nil, expression: self)])
        )
    }

    /// Returns a new expression that calls the decoder initializer.
    ///
    /// Assumes the existence of an "decoder" variable in the current scope,
    /// and assumes that the result is assigned to a variable with a defined
    /// type, as the type checking relies on type inference.
    /// - Returns: An expression representing the initialization of an instance using the decoder.
    static func initFromDecoderExpr() -> Expression {
        .dot("init").call([.init(label: "from", expression: .identifierPattern("decoder"))])
    }

    /// Returns a new expression that calls the decoder initializer for
    /// non-key-value pair values.
    ///
    /// Assumes the existence of a "decoder" variable in the current scope,
    /// and assumes that the result is assigned to a variable with a defined
    /// type, as the type checking relies on type inference.
    /// - Returns: An Expression representing the result of calling the decoder initializer
    ///   for non-key-value pair values.
    static func decodeFromSingleValueContainerExpr() -> Expression {
        .identifierPattern("decoder").dot("decodeFromSingleValueContainer").call([])
    }
    /// Returns a new expression that wraps the provided expression in
    /// a do/catch block where the error is appended to an array.
    ///
    /// Assumes the existence of an "errors" variable in the current scope.
    /// - Returns: The expression.
    func wrapInDoCatchAppendArrayExpr() -> Expression { [CodeBlock.expression(self)].wrapInDoCatchAppendArrayExpr() }
}

fileprivate extension Array where Element == CodeBlock {
    /// Returns a new expression that wraps the provided code blocks in
    /// a do/catch block where the error is appended to an array.
    ///
    /// Assumes the existence of an "errors" variable in the current scope.
    /// - Returns: The expression.
    func wrapInDoCatchAppendArrayExpr() -> Expression {
        .do(
            self,
            catchBody: [
                .expression(
                    .identifierPattern("errors").dot("append")
                        .call([.init(label: nil, expression: .identifierPattern("error"))])
                )
            ]
        )
    }
}

fileprivate extension Declaration {

    /// Returns a declaration of a container variable for CodingKeys.
    /// - Returns: A variable declaration representing a container for CodingKeys.
    static func decoderContainerOfKeysVar() -> Declaration {
        .variable(
            kind: .let,
            left: "container",
            right: .try(
                .identifierPattern("decoder").dot("container")
                    .call([.init(label: "keyedBy", expression: .identifierType(.member("CodingKeys")).dot("self"))])
            )
        )
    }
    /// Creates a new declaration that creates a local array of errors.
    /// - Returns: The declaration.
    static func createErrorArrayDecl() -> Declaration {
        .variable(kind: .var, left: "errors", type: .array(.any(.member("Error"))), right: .literal(.array([])))
    }
}

fileprivate extension FileTranslator {

    /// Returns a declaration of an encoder method definition.
    /// - Parameter body: An array of code blocks for the implementation.
    /// - Returns: A function declaration.
    func encoderFunction(body: [CodeBlock]) -> Declaration {
        .function(
            accessModifier: config.access,
            kind: .function(name: "encode"),
            parameters: [.init(label: "to", name: "encoder", type: .any(.member("Encoder")))],
            keywords: [.throws],
            body: body
        )
    }

    /// Returns a declaration of a decoder initializer.
    /// - Parameter body: An array of code blocks for the implementation.
    /// - Returns: A function declaration.
    func decoderInitializer(body: [CodeBlock]) -> Declaration {
        .function(
            accessModifier: config.access,
            kind: .initializer,
            parameters: [.init(label: "from", name: "decoder", type: .any(.member("Decoder")))],
            keywords: [.throws],
            body: body
        )
    }
}
