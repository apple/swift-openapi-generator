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

extension FileTranslator {

    /// Returns a declaration of the specified string-based enum schema.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared enum.
    ///   - openAPIDescription: A user-specified description from the OpenAPI
    ///   document.
    ///   - allowedValues: The enumerated allowed values.
    func translateStringEnum(
        typeName: TypeName,
        userDescription: String?,
        allowedValues: [AnyCodable]
    ) throws -> Declaration {

        let rawValues = try allowedValues.map(\.value)
            .map { anyValue in
                guard let string = anyValue as? String else {
                    throw GenericError(message: "Disallowed value for a string enum '\(typeName)': \(anyValue)")
                }
                return string
            }

        let knownCases: [Declaration] =
            rawValues
            .map { rawValue in
                let caseName = swiftSafeName(for: rawValue)
                return .enumCase(
                    name: caseName,
                    kind: .nameOnly
                )
            }
        let undocumentedCase: Declaration = .commentable(
            .doc("Parsed a raw value that was not defined in the OpenAPI document."),
            .enumCase(
                name: Constants.StringEnum.undocumentedCaseName,
                kind: .nameWithAssociatedValues([
                    .init(type: "String")
                ])
            )
        )

        let rawRepresentableInitializer: Declaration
        do {
            let knownCases: [SwitchCaseDescription] = rawValues.map { rawValue in
                .init(
                    kind: .case(.literal(rawValue)),
                    body: [
                        .expression(
                            .assignment(
                                Expression
                                    .identifier("self")
                                    .equals(
                                        .dot(swiftSafeName(for: rawValue))
                                    )
                            )
                        )
                    ]
                )
            }
            let unknownCase: SwitchCaseDescription = .init(
                kind: .default,
                body: [
                    .expression(
                        .assignment(
                            Expression
                                .identifier("self")
                                .equals(
                                    .functionCall(
                                        calledExpression: .dot(
                                            Constants
                                                .StringEnum
                                                .undocumentedCaseName
                                        ),
                                        arguments: [
                                            .identifier("rawValue")
                                        ]
                                    )
                                )
                        )
                    )
                ]
            )
            rawRepresentableInitializer = .function(
                .init(
                    accessModifier: config.access,
                    kind: .initializer(failable: true),
                    parameters: [
                        .init(label: "rawValue", type: "String")
                    ],
                    body: [
                        .expression(
                            .switch(
                                switchedExpression: .identifier("rawValue"),
                                cases: knownCases + [unknownCase]
                            )
                        )
                    ]
                )
            )
        }

        let rawValueGetter: Declaration
        do {
            let knownCases: [SwitchCaseDescription] = rawValues.map { rawValue in
                .init(
                    kind: .case(.dot(swiftSafeName(for: rawValue))),
                    body: [
                        .expression(
                            .return(.literal(rawValue))
                        )
                    ]
                )
            }
            let unknownCase: SwitchCaseDescription = .init(
                kind: .case(
                    .valueBinding(
                        kind: .let,
                        value: .init(
                            calledExpression: .dot(
                                Constants.StringEnum.undocumentedCaseName
                            ),
                            arguments: [
                                .identifier("string")
                            ]
                        )
                    )
                ),
                body: [
                    .expression(
                        .return(.identifier("string"))
                    )
                ]
            )

            let variableDescription: VariableDescription = .init(
                accessModifier: config.access,
                kind: .var,
                left: "rawValue",
                type: "String",
                body: [
                    .expression(
                        .switch(
                            switchedExpression: .identifier("self"),
                            cases: [unknownCase] + knownCases
                        )
                    )
                ]
            )

            rawValueGetter = .variable(
                variableDescription
            )
        }

        let allCasesGetter: Declaration
        do {
            let caseExpressions: [Expression] = rawValues.map { rawValue in
                .memberAccess(.init(right: swiftSafeName(for: rawValue)))
            }
            allCasesGetter = .variable(
                .init(
                    accessModifier: config.access,
                    isStatic: true,
                    kind: .var,
                    left: "allCases",
                    type: typeName.asUsage.asArray.shortSwiftName,
                    body: [
                        .expression(.literal(.array(caseExpressions)))
                    ]
                )
            )
        }

        let enumDescription: EnumDescription = .init(
            isFrozen: true,
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            conformances: Constants.StringEnum.conformances,
            members: knownCases + [
                undocumentedCase,
                rawRepresentableInitializer,
                rawValueGetter,
                allCasesGetter,
            ]
        )

        let comment: Comment? =
            typeName
            .docCommentWithUserDescription(userDescription)
        return .commentable(
            comment,
            .enum(enumDescription)
        )
    }
}
