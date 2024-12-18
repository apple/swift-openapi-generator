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

/// Represents a server variable and the function of generation that should be applied.
protocol ServerVariableGenerator {
    /// Returns the declaration (enum) that should be added to the server's namespace.
    /// If the server variable does not require any codegen then it should return `nil`.
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

extension TypesFileTranslator {
    /// Returns a declaration of a namespace (enum) for a specific server and will define
    /// one enum member for each of the server's variables in the OpenAPI Document.
    /// If the server does not define variables, no declaration will be generated.
    /// - Parameters:
    ///   - index: The index of the server in the list of servers defined
    ///   in the OpenAPI document.
    ///   - server: The server variables information.
    ///   - generateAsEnum: Whether the enum generator is allowed, if `false`
    ///   only `RawStringTranslatedServerVariable` generators will be returned.
    /// - Returns: A declaration of the server variables namespace, or `nil` if no
    /// variables are declared.
    func translateServerVariables(index: Int, server: OpenAPI.Server, generateAsEnum: Bool)
        -> [any ServerVariableGenerator]
    {
        server.variables.map { key, variable in
            guard generateAsEnum, let enumValues = variable.enum else {
                return RawStringTranslatedServerVariable(key: key, variable: variable, context: context)
            }
            return GeneratedEnumTranslatedServerVariable(
                key: key,
                variable: variable,
                enumValues: enumValues,
                accessModifier: config.access,
                context: context
            )
        }
    }

    // MARK: Generators

    /// Represents a variable that is required to be represented as a `Swift.String`.
    private struct RawStringTranslatedServerVariable: ServerVariableGenerator {
        /// The key of the variable defined in the Open API document.
        let key: String

        /// The ``key`` after being santized for use as an identifier.
        let swiftSafeKey: String

        /// The server variable information.
        let variable: OpenAPI.Server.Variable

        /// Create a generator for an Open API "Server Variable Object" that is represented
        /// by a `Swift.String` in the generated output.
        ///
        /// - Parameters:
        ///   - key: The key of the variable defined in the Open API document.
        ///   - variable: The server variable information.
        ///   - context: The translator context the generator should use to create
        ///   Swift safe identifiers.
        init(key: String, variable: OpenAPI.Server.Variable, context: TranslatorContext) {
            self.key = key
            swiftSafeKey = context.safeNameGenerator.swiftMemberName(for: key)
            self.variable = variable
        }

        /// Returns the declaration (enum) that should be added to the server's namespace.
        /// If the server variable does not require any codegen then it should return `nil`.
        var declaration: Declaration? {
            // A variable being represented by a `Swift.String` does not have a declaration that needs to
            // be added to the server's namespace.
            nil
        }

        /// Returns the description of the parameter that will be used to define the variable
        /// in the static method for a given server.
        var parameter: ParameterDescription {
            .init(label: swiftSafeKey, type: .init(TypeName.string), defaultValue: .literal(variable.default))
        }

        /// Returns an expression for the variable initializer that is used in the body of a server's
        /// static method by passing it along to the URL resolver.
        var initializer: Expression {
            var arguments: [FunctionArgumentDescription] = [
                .init(label: "name", expression: .literal(key)),
                .init(label: "value", expression: .identifierPattern(swiftSafeKey)),
            ]
            if let allowedValues = variable.enum {
                arguments.append(
                    .init(label: "allowedValues", expression: .literal(.array(allowedValues.map { .literal($0) })))
                )
            }
            return .dot("init").call(arguments)
        }

        /// Returns the description of this variables documentation for the function comment of
        /// the server's static method.
        var functionComment: (name: String, comment: String?) { (name: swiftSafeKey, comment: variable.description) }
    }

    /// Represents an Open API "Server Variable Object" that will be generated as an enum and added
    /// to the server's namespace.
    private struct GeneratedEnumTranslatedServerVariable: ServerVariableGenerator {
        /// The key of the variable defined in the Open API document.
        let key: String

        /// The ``key`` after being santized for use as an identifier.
        let swiftSafeKey: String

        /// The ``key`` after being santized for use as the enum identifier.
        let enumName: String

        /// The server variable information.
        let variable: OpenAPI.Server.Variable

        /// The 'enum' values of the variable as defined in the Open API document.
        let enumValues: [String]

        /// The access modifier to use for generated declarations.
        let accessModifier: AccessModifier

        /// The translator context the generator should use to create Swift safe identifiers.
        let context: TranslatorContext

        /// Create a generator for an Open API "Server Variable Object" that is represented
        /// by an enumeration in the generated output.
        ///
        /// - Parameters:
        ///   - key: The key of the variable defined in the Open API document.
        ///   - variable: The server variable information.
        ///   - enumValues: The 'enum' values of the variable as defined in the Open API document.
        ///   - accessModifier: The access modifier to use for generated declarations.
        ///   - context: The translator context the generator should use to create
        ///   Swift safe identifiers.
        init(
            key: String,
            variable: OpenAPI.Server.Variable,
            enumValues: [String],
            accessModifier: AccessModifier,
            context: TranslatorContext
        ) {
            self.key = key
            swiftSafeKey = context.safeNameGenerator.swiftMemberName(for: key)
            enumName = context.safeNameGenerator.swiftTypeName(for: key.localizedCapitalized)
            self.variable = variable
            self.enumValues = enumValues
            self.context = context
            self.accessModifier = accessModifier
        }

        /// Returns the declaration (enum) that should be added to the server's namespace.
        /// If the server variable does not require any codegen then it should return `nil`.
        var declaration: Declaration? {
            let description: String = if let description = variable.description { description + "\n\n" } else { "" }

            return .commentable(
                .doc(
                    """
                    \(description)The "\(key)" variable defined in the OpenAPI document. The default value is "\(variable.default)".
                    """
                ),
                .enum(
                    isFrozen: true,
                    accessModifier: accessModifier,
                    name: enumName,
                    conformances: Constants.ServerURL.Variable.conformances,
                    members: enumValues.map(translateVariableCase)
                )
            )
        }

        /// Returns the description of the parameter that will be used to define the variable
        /// in the static method for a given server.
        var parameter: ParameterDescription {
            .init(
                label: swiftSafeKey,
                type: .member([enumName]),
                defaultValue: .memberAccess(.dot(context.safeNameGenerator.swiftMemberName(for: variable.default)))
            )
        }

        /// Returns an expression for the variable initializer that is used in the body of a server's
        /// static method by passing it along to the URL resolver.
        var initializer: Expression {
            .dot("init")
                .call([
                    .init(label: "name", expression: .literal(key)),
                    .init(
                        label: "value",
                        expression: .memberAccess(.init(left: .identifierPattern(swiftSafeKey), right: "rawValue"))
                    ),
                ])
        }

        /// Returns the description of this variables documentation for the function comment of
        /// the server's static method.
        var functionComment: (name: String, comment: String?) { (name: swiftSafeKey, comment: variable.description) }

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
            let caseName = context.safeNameGenerator.swiftMemberName(for: name)
            return .enumCase(name: caseName, kind: caseName == name ? .nameOnly : .nameWithRawValue(.string(name)))
        }
    }
}
