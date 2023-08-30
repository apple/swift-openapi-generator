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
        let knownKeys =
            properties
            .map(\.originalName)
        let knownKeysFunctionArg = FunctionArgumentDescription(
            label: "knownKeys",
            expression: .literal(
                .array(
                    knownKeys.map { .literal($0) }
                )
            )
        )
        switch strategy {
        case .synthesized:
            return nil
        case .enforcingNoAdditionalProperties:
            return translateStructBlueprintCustomDecoder(
                properties: properties,
                trailingCodeBlocks: [
                    .expression(
                        .try(
                            .identifier("decoder")
                                .dot("ensureNoAdditionalProperties")
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
                            left: .identifier("additionalProperties"),
                            right: .try(
                                .identifier("decoder")
                                    .dot("decodeAdditionalProperties")
                                    .call([knownKeysFunctionArg])
                            )
                        )
                    )
                ]
            )
        case .allOf:
            return translateStructBlueprintAllOfDecoder(
                properties: properties
            )
        case .anyOf:
            return translateStructBlueprintAnyOfDecoder(
                properties: properties
            )
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
        case .synthesized, .enforcingNoAdditionalProperties:
            return nil
        case .allowingAdditionalProperties:
            return translateStructBlueprintCustomEncoder(
                properties: properties,
                trailingCodeBlocks: [
                    .expression(
                        .try(
                            .identifier("encoder")
                                .dot("encodeAdditionalProperties")
                                .call([
                                    .init(
                                        label: nil,
                                        expression: .identifier("additionalProperties")
                                    )
                                ])
                        )
                    )
                ]
            )
        case .allOf:
            return translateStructBlueprintAllOfEncoder(
                properties: properties
            )
        case .anyOf:
            return translateStructBlueprintAnyOfEncoder(
                properties: properties
            )
        }
    }

    // MARK: - Custom encoder and decoder

    /// Returns a declaration of a decoder implementation.
    /// - Parameters:
    ///   - properties: The properties to decode.
    ///   - trailingCodeBlocks: Additional code blocks to add at the end of
    ///   the body of the decoder initializer.
    func translateStructBlueprintCustomDecoder(
        properties: [PropertyBlueprint],
        trailingCodeBlocks: [CodeBlock] = []
    ) -> Declaration {
        let containerVarDecl: Declaration = .decoderContainerOfKeysVar()
        let assignExprs: [Expression] = properties.map { property in
            let typeUsage = property.typeUsage
            return .assignment(
                left: .identifier(property.swiftSafeName),
                right: .try(
                    .identifier("container")
                        .dot("decode\(typeUsage.isOptional ? "IfPresent" : "")")
                        .call([
                            .init(
                                label: nil,
                                expression:
                                    .identifier(
                                        typeUsage.fullyQualifiedNonOptionalSwiftName
                                    )
                                    .dot("self")
                            ),
                            .init(
                                label: "forKey",
                                expression: .dot(property.swiftSafeName)
                            ),
                        ])
                )
            )
        }
        let decodingCodeBlocks: [CodeBlock]
        if !properties.isEmpty {
            decodingCodeBlocks =
                [
                    .declaration(containerVarDecl)
                ] + assignExprs.map { .expression($0) }
        } else {
            decodingCodeBlocks = []
        }
        return decoderInitializer(
            body: decodingCodeBlocks + trailingCodeBlocks
        )
    }

    /// Returns a declaration of an encoder implementation.
    /// - Parameters:
    ///   - properties: The properties to encode.
    ///   - trailingCodeBlocks: Additional code blocks to add at the end of
    ///   the body of the encoder initializer.
    func translateStructBlueprintCustomEncoder(
        properties: [PropertyBlueprint],
        trailingCodeBlocks: [CodeBlock] = []
    ) -> Declaration {
        let containerVarDecl: Declaration = .variable(
            kind: .var,
            left: "container",
            right: .identifier("encoder").dot("container")
                .call([
                    .init(
                        label: "keyedBy",
                        expression: .identifier("CodingKeys").dot("self")
                    )
                ])
        )
        let encodeExprs: [Expression] = properties.map { property in
            .try(
                .identifier("container")
                    .dot("encode\(property.typeUsage.isOptional ? "IfPresent" : "")")
                    .call([
                        .init(
                            label: nil,
                            expression: .identifier(property.swiftSafeName)
                        ),
                        .init(
                            label: "forKey",
                            expression: .dot(property.swiftSafeName)
                        ),
                    ])
            )
        }
        let encodingCodeBlocks: [CodeBlock]
        if !properties.isEmpty {
            encodingCodeBlocks =
                [
                    .declaration(containerVarDecl)
                ] + encodeExprs.map { .expression($0) }
        } else {
            encodingCodeBlocks = []
        }
        return encoderFunction(
            body: encodingCodeBlocks + trailingCodeBlocks
        )
    }

    // MARK: - AllOf encoder and decoder

    /// Returns a declaration of an allOf decoder implementation.
    /// - Parameters:
    ///   - properties: The properties to decode.
    func translateStructBlueprintAllOfDecoder(
        properties: [PropertyBlueprint]
    ) -> Declaration {
        let assignExprs: [Expression] = properties.map { property in
            .assignment(
                left: .identifier(property.swiftSafeName),
                right: .try(.initFromDecoderExpr())
            )
        }
        return decoderInitializer(body: assignExprs.map { .expression($0) })
    }

    /// Returns a declaration of an allOf encoder implementation.
    /// - Parameters:
    ///   - properties: The properties to encode.
    func translateStructBlueprintAllOfEncoder(
        properties: [PropertyBlueprint]
    ) -> Declaration {
        let encodeExprs: [Expression] = properties.map { property in
            .identifier(property.swiftSafeName)
                .encodeExpr()
        }
        return encoderFunction(body: encodeExprs.map { .expression($0) })
    }

    // MARK: - AnyOf encoder and decoder

    /// Returns a declaration of an anyOf decoder implementation.
    /// - Parameters:
    ///   - properties: The properties to decode.
    func translateStructBlueprintAnyOfDecoder(
        properties: [PropertyBlueprint]
    ) -> Declaration {
        let assignExprs: [Expression] = properties.map { property in
            .assignment(
                left: .identifier(property.swiftSafeName),
                right: .optionalTry(.initFromDecoderExpr())
            )
        }
        let atLeastOneNotNilCheckExpr: Expression = .try(
            .identifier("DecodingError")
                .dot("verifyAtLeastOneSchemaIsNotNil")
                .call([
                    .init(
                        label: nil,
                        expression: .literal(
                            .array(
                                properties.map { .identifier($0.swiftSafeName) }
                            )
                        )
                    ),
                    .init(
                        label: "type",
                        expression: .identifier("Self").dot("self")
                    ),
                    .init(
                        label: "codingPath",
                        expression: .identifier("decoder").dot("codingPath")
                    ),
                ])
        )
        return decoderInitializer(
            body: assignExprs.map { .expression($0) } + [
                .expression(atLeastOneNotNilCheckExpr)
            ]
        )
    }

    /// Returns a declaration of an anyOf encoder implementation.
    /// - Parameters:
    ///   - properties: The properties to encode.
    func translateStructBlueprintAnyOfEncoder(
        properties: [PropertyBlueprint]
    ) -> Declaration {
        let encodeExprs: [Expression] = properties.map { property in
            .identifier(property.swiftSafeName)
                .optionallyChained()
                .encodeExpr()
        }
        return encoderFunction(body: encodeExprs.map { .expression($0) })
    }

    // MARK: - OneOf encoder and decoder

    /// Returns a declaration of a oneOf without discriminator decoder implementation.
    /// - Parameters:
    ///   - properties: The properties to decode.
    func translateOneOfWithoutDiscriminatorDecoder(
        caseNames: [String]
    ) -> Declaration {
        let assignExprs: [Expression] = caseNames.map { caseName in
            .doStatement(
                .init(
                    doStatement: [
                        .expression(
                            .assignment(
                                left: .identifier("self"),
                                right: .dot(caseName)
                                    .call([
                                        .init(
                                            label: nil,
                                            expression: .try(.initFromDecoderExpr())
                                        )
                                    ])
                            )
                        ),
                        .expression(.return()),
                    ],
                    catchBody: []
                )
            )
        }

        let otherExprs: [CodeBlock] = [
            .expression(
                translateOneOfDecoderThrowOnUnknownExpr()
            )
        ]
        return decoderInitializer(
            body: (assignExprs).map { .expression($0) } + otherExprs
        )
    }

    /// Returns an expression that throws an error when a oneOf failed
    /// to match any documented cases.
    func translateOneOfDecoderThrowOnUnknownExpr() -> Expression {
        .unaryKeyword(
            kind: .throw,
            expression: .identifier("DecodingError")
                .dot("failedToDecodeOneOfSchema")
                .call([
                    .init(
                        label: "type",
                        expression: .identifier("Self").dot("self")
                    ),
                    .init(
                        label: "codingPath",
                        expression: .identifier("decoder").dot("codingPath")
                    ),
                ])
        )
    }

    /// Returns a declaration of a oneOf with a discriminator decoder implementation.
    func translateOneOfWithDiscriminatorDecoder(
        discriminatorName: String,
        cases: [(caseName: String, rawNames: [String])]
    ) -> Declaration {
        let cases: [SwitchCaseDescription] =
            cases
            .map { caseName, rawNames in
                .init(
                    kind: .multiCase(rawNames.map { .literal($0) }),
                    body: [
                        .expression(
                            .assignment(
                                left: .identifier("self"),
                                right: .dot(caseName)
                                    .call([
                                        .init(
                                            label: nil,
                                            expression: .try(
                                                .initFromDecoderExpr()
                                            )
                                        )
                                    ])
                            )
                        )
                    ]
                )
            }
        let otherExprs: [CodeBlock] = [
            .expression(
                translateOneOfDecoderThrowOnUnknownExpr()
            )
        ]
        let body: [CodeBlock] = [
            .declaration(.decoderContainerOfKeysVar()),
            .declaration(
                .variable(
                    kind: .let,
                    left: Constants.OneOf.discriminatorName,
                    right: .try(
                        .identifier("container")
                            .dot("decode")
                            .call([
                                .init(
                                    label: nil,
                                    expression: .identifier("String").dot("self")
                                ),
                                .init(
                                    label: "forKey",
                                    expression: .dot(discriminatorName)
                                ),
                            ])
                    )
                )
            ),
            .expression(
                .switch(
                    switchedExpression: .identifier(Constants.OneOf.discriminatorName),
                    cases: cases + [
                        .init(
                            kind: .default,
                            body: otherExprs
                        )
                    ]
                )
            ),
        ]
        return decoderInitializer(
            body: body
        )
    }

    /// Returns a declaration of a oneOf encoder implementation.
    /// - Parameters:
    ///   - properties: The properties to encode.
    func translateOneOfEncoder(
        caseNames: [String]
    ) -> Declaration {
        let switchExpr: Expression = .switch(
            switchedExpression: .identifier("self"),
            cases: caseNames.map { caseName in
                .init(
                    kind: .case(.dot(caseName), ["value"]),
                    body: [
                        .expression(
                            .identifier("value")
                                .encodeExpr()
                        )
                    ]
                )
            }
        )
        return encoderFunction(body: [.expression(switchExpr)])
    }
}

fileprivate extension Expression {
    /// Returns a new expression that calls the encode method on the current
    /// expression.
    ///
    /// Assumes the existence of an "encoder" variable in the current scope.
    func encodeExpr() -> Expression {
        .try(
            self
                .dot("encode")
                .call([
                    .init(
                        label: "to",
                        expression: .identifier("encoder")
                    )
                ])
        )
    }

    /// Returns a new expression that calls the decoder initializer.
    ///
    /// Assumes the existence of an "decoder" variable in the current scope,
    /// and assumes that the result is assigned to a variable with a defined
    /// type, as the type checking relies on type inference.
    static func initFromDecoderExpr() -> Expression {
        .dot("init")
            .call([
                .init(
                    label: "from",
                    expression: .identifier("decoder")
                )
            ])
    }
}

fileprivate extension Declaration {

    /// Returns a declaration of a container variable for CodingKeys.
    static func decoderContainerOfKeysVar() -> Declaration {
        .variable(
            kind: .let,
            left: "container",
            right: .try(
                .identifier("decoder")
                    .dot("container")
                    .call([
                        .init(
                            label: "keyedBy",
                            expression: .identifier("CodingKeys").dot("self")
                        )
                    ])
            )
        )
    }
}

fileprivate extension FileTranslator {

    // MARK: - Utilities

    /// Returns a declaration of an encoder method definition.
    /// - Parameter body: An array of code blocks for the implementation.
    /// - Returns: A function declaration.
    func encoderFunction(body: [CodeBlock]) -> Declaration {
        .function(
            accessModifier: config.access,
            kind: .function(name: "encode"),
            parameters: [
                .init(label: "to", name: "encoder", type: "any Encoder")
            ],
            keywords: [
                .throws
            ],
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
            parameters: [
                .init(label: "from", name: "decoder", type: "any Decoder")
            ],
            keywords: [
                .throws
            ],
            body: body
        )
    }
}
