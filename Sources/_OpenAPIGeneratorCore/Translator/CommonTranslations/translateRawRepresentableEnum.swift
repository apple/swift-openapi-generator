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

    /// Returns a declaration of the specified raw representable enum.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared enum.
    ///   - conformances: The list of types the enum conforms to.
    ///   - userDescription: The contents of the documentation comment.
    ///   - cases: The list of cases to generate.
    ///   - unknownCaseName: The name of the extra unknown case that preserves
    ///     the string value that doesn't fit any of the cases. If nil is
    ///     passed, the unknown case is not generated.
    ///   - unknownCaseDescription: The contents of the documentation comment
    ///     for the unknown case.
    ///   - customSwitchedExpression: A closure
    /// - Throws: An error if there's an issue generating the declaration.
    /// - Returns: The generated declaration.
    func translateRawRepresentableEnum(
        typeName: TypeName,
        conformances: [String],
        userDescription: String?,
        cases: [(caseName: String, rawExpr: LiteralDescription)],
        unknownCaseName: String?,
        unknownCaseDescription: String?,
        customSwitchedExpression: (Expression) -> Expression = { $0 }
    ) throws -> Declaration {

        let generateUnknownCases = unknownCaseName != nil
        let knownCases: [Declaration] = cases.map { caseName, rawExpr in
            .enumCase(name: caseName, kind: generateUnknownCases ? .nameOnly : .nameWithRawValue(rawExpr))
        }

        let otherMembers: [Declaration]
        if let unknownCaseName {
            let undocumentedCase: Declaration = .commentable(
                unknownCaseDescription.flatMap { .doc($0) },
                .enumCase(name: unknownCaseName, kind: .nameWithAssociatedValues([.init(type: .init(TypeName.string))]))
            )
            let rawRepresentableInitializer: Declaration
            do {
                let knownCases: [SwitchCaseDescription] = cases.map { caseName, rawValue in
                    .init(
                        kind: .case(.literal(rawValue)),
                        body: [.expression(.assignment(Expression.identifierPattern("self").equals(.dot(caseName))))]
                    )
                }
                let unknownCase = SwitchCaseDescription(
                    kind: .default,
                    body: [
                        .expression(
                            .assignment(
                                Expression.identifierPattern("self")
                                    .equals(
                                        .functionCall(
                                            calledExpression: .dot(unknownCaseName),
                                            arguments: [.identifierPattern("rawValue")]
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
                        parameters: [.init(label: "rawValue", type: .init(TypeName.string))],
                        body: [
                            .expression(
                                .switch(
                                    switchedExpression: customSwitchedExpression(.identifierPattern("rawValue")),
                                    cases: knownCases + [unknownCase]
                                )
                            )
                        ]
                    )
                )
            }

            let rawValueGetter: Declaration
            do {
                let knownCases: [SwitchCaseDescription] = cases.map { caseName, rawValue in
                    .init(kind: .case(.dot(caseName)), body: [.expression(.return(.literal(rawValue)))])
                }
                let unknownCase = SwitchCaseDescription(
                    kind: .case(
                        .valueBinding(
                            kind: .let,
                            value: .init(
                                calledExpression: .dot(unknownCaseName),
                                arguments: [.identifierPattern("string")]
                            )
                        )
                    ),
                    body: [.expression(.return(.identifierPattern("string")))]
                )

                rawValueGetter = .variable(
                    accessModifier: config.access,
                    kind: .var,
                    left: "rawValue",
                    type: .init(TypeName.string),
                    getter: [
                        .expression(
                            .switch(switchedExpression: .identifierPattern("self"), cases: [unknownCase] + knownCases)
                        )
                    ]
                )
            }

            let allCasesGetter: Declaration
            do {
                let caseExpressions: [Expression] = cases.map { caseName, _ in .memberAccess(.init(right: caseName)) }
                allCasesGetter = .variable(
                    accessModifier: config.access,
                    isStatic: true,
                    kind: .var,
                    left: "allCases",
                    type: .array(.member("Self")),
                    getter: [.expression(.literal(.array(caseExpressions)))]
                )
            }
            otherMembers = [undocumentedCase, rawRepresentableInitializer, rawValueGetter, allCasesGetter]
        } else {
            otherMembers = []
        }

        let enumDescription = EnumDescription(
            isFrozen: true,
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            conformances: conformances,
            members: knownCases + otherMembers
        )
        let comment: Comment? = typeName.docCommentWithUserDescription(userDescription)
        return .commentable(comment, .enum(enumDescription))
    }
}
