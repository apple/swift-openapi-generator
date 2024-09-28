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

extension TypesFileTranslator {
    /// Returns a declaration of a namespace (enum) for a specific server and will define
    /// one enum member for each of the server's variables in the OpenAPI Document.
    /// If the server does not define variables, no declaration will be generated.
    /// - Parameters:
    ///   - index: The index of the server in the list of servers defined
    ///   in the OpenAPI document.
    ///   - server: The server variables information.
    /// - Returns: A declaration of the server variables namespace, or `nil` if no
    /// variables are declared.
    func translateServerVariables(index: Int, server: OpenAPI.Server, generateAsEnum: Bool) -> [any ServerVariableGenerator] {
        return server.variables.map { (key, variable) in
            guard generateAsEnum, let enumValues = variable.enum else {
                return RawStringTranslatedServerVariable(
                    key: key,
                    variable: variable,
                    asSwiftSafeName: swiftSafeName(for:)
                )
            }

            return GeneratedEnumTranslatedServerVariable(
                key: key,
                variable: variable,
                enumValues: enumValues,
                accessModifier: config.access,
                asSwiftSafeName: swiftSafeName(for:)
            )
        }
    }

    // MARK: Generators
    
    /// Represents a server variable and the function of generation that should be applied.
    protocol ServerVariableGenerator {
        /// Returns the declaration (enum) that should be added to the `Variables.Server#`
        /// namespace. If the server variable does not require any codegen then it should
        /// return `nil`.
        var declaration: Declaration? { get }

        /// Returns the description of the parameter that will be used to define the variable
        /// in the static method for a given server.
        var parameter: ParameterDescription { get }

        /// Returns an expression for the variable initializer that is used in the body of a server's
        /// static method by passing it along to the URL resolver.
        var initializer: Expression { get }

        /// Returns the description of this variables documentation for the function comment of
        /// the server's static method.
        var functionComment: (name: String, comment: String?) { get }
    }

    /// Represents a variable that is required to be represented as a `Swift.String`.
    private struct RawStringTranslatedServerVariable: ServerVariableGenerator {
        let key: String
        let swiftSafeKey: String
        let variable: OpenAPI.Server.Variable

        init(key: String, variable: OpenAPI.Server.Variable, asSwiftSafeName: @escaping (String) -> String) {
            self.key = key
            swiftSafeKey = asSwiftSafeName(key)
            self.variable = variable
        }

        /// A variable being represented by a `Swift.String` does not have a declaration that needs to
        /// be added to the `Variables.Server#` namespace.
        var declaration: Declaration? { nil }

        /// Returns the description of the parameter that will be used to define the variable
        /// in the static method for a given server.
        var parameter: ParameterDescription {
            return .init(
                label: swiftSafeKey,
                type: .init(TypeName.string),
                defaultValue: .literal(variable.default)
            )
        }

        /// Returns an expression for the variable initializer that is used in the body of a server's
        /// static method by passing it along to the URL resolver.
        var initializer: Expression {
            var arguments: [FunctionArgumentDescription] = [
                .init(label: "name", expression: .literal(key)),
                .init(label: "value", expression: .identifierPattern(swiftSafeKey)),
            ]
            if let allowedValues = variable.enum {
                arguments.append(.init(
                    label: "allowedValues",
                    expression: .literal(.array(allowedValues.map { .literal($0) }))
                ))
            }
            return .dot("init").call(arguments)
        }

        /// Returns the description of this variables documentation for the function comment of
        /// the server's static method.
        var functionComment: (name: String, comment: String?) {
            (name: swiftSafeKey, comment: variable.description)
        }
    }

    /// Represents a variable that will be generated as an enum and added to the `Variables.Server#`
    /// namespace. The enum will contain a `default` static case which returns the default defined in
    /// the OpenAPI Document.
    private struct GeneratedEnumTranslatedServerVariable: ServerVariableGenerator {
        let key: String
        let swiftSafeKey: String
        let enumName: String
        let variable: OpenAPI.Server.Variable
        let enumValues: [String]

        let accessModifier: AccessModifier
        let asSwiftSafeName: (String) -> String

        init(key: String, variable: OpenAPI.Server.Variable, enumValues: [String], accessModifier: AccessModifier, asSwiftSafeName: @escaping (String) -> String) {
            self.key = key
            swiftSafeKey = asSwiftSafeName(key)
            enumName = asSwiftSafeName(key.localizedCapitalized)
            self.variable = variable
            self.enumValues = enumValues

            self.asSwiftSafeName = asSwiftSafeName
            self.accessModifier = accessModifier
        }

        /// Returns the declaration (enum) that should be added to the `Variables.Server#`
        /// namespace.
        var declaration: Declaration? {
            let description: String = if let description = variable.description {
                description + "\n\n"
            } else {
                ""
            }

            return .commentable(
                .doc("""
                \(description)The "\(key)" variable defined in the OpenAPI document. The default value is "\(variable.default)".
                """),
                .enum(
                    isFrozen: true,
                    accessModifier: accessModifier,
                    name: enumName,
                    conformances: [
                        TypeName.string.fullyQualifiedSwiftName,
                    ],
                    members: enumValues.map(translateVariableCase)
                )
            )
        }

        /// Returns the description of the parameter that will be used to define the variable
        /// in the static method for a given server.
        var parameter: ParameterDescription {
            let safeDefault = asSwiftSafeName(variable.default)
            let memberPath: [String] = [
                enumName
            ]
            return .init(
                label: swiftSafeKey,
                type: .member(memberPath),
                defaultValue: .identifierType(.member(memberPath + CollectionOfOne(safeDefault)))
            )
        }

        /// Returns an expression for the variable initializer that is used in the body of a server's
        /// static method by passing it along to the URL resolver.
        var initializer: Expression {
            .dot("init").call(
                [
                    .init(label: "name", expression: .literal(key)),
                    .init(label: "value", expression: .memberAccess(.init(
                        left: .identifierPattern(swiftSafeKey),
                        right: "rawValue"
                    ))),
                ]
            )
        }

        /// Returns the description of this variables documentation for the function comment of
        /// the server's static method.
        var functionComment: (name: String, comment: String?) {
            (name: swiftSafeKey, comment: variable.description)
        }

        /// Returns an enum case declaration for a raw string enum.
        ///
        /// If the name does not need to be converted to a Swift safe identifier then the
        /// enum case will not define a raw value and rely on the implicit generation from
        /// Swift. Otherwise the enum case name will be the Swift safe name and a string
        /// raw value will be set to the original name.
        ///
        /// - Parameter name: The original name.
        /// - Returns: A declaration of an enum case.
        private func translateVariableCase(_ name: String) -> Declaration {
            let caseName = asSwiftSafeName(name)
            if caseName == name {
                return .enumCase(name: caseName, kind: .nameOnly)
            } else {
                return .enumCase(name: caseName, kind: .nameWithRawValue(.string(name)))
            }
        }
    }
}
