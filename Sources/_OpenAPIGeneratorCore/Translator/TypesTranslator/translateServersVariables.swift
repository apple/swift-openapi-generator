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

    /// Returns the name used for the enum which represents a server variable defined in the OpenAPI
    /// document.
    /// - Parameter variable: The variable information.
    /// - Returns: A name that can be safely used for the enum.
    func translateVariableToEnumName(_ variable: (key: String, value: OpenAPI.Server.Variable)) -> String {
        return swiftSafeName(for: variable.key.localizedCapitalized)
    }

    /// Returns the name used for the namespace (enum) which contains a specific server's variables.
    /// - Parameter index: The array index of the server.
    /// - Returns: A name that can be safely used for the namespace.
    func translateServerVariablesEnumName(for index: Int) -> String {
        return "\(Constants.ServerURL.serverVariablesNamespacePrefix)\(index + 1)"
    }

    /// Returns a declaration of a variable enum case for the provided value. If the value can be
    /// safely represented as an identifier then the enum case is name only, otherwise the case
    /// will have a raw value set to the provided value to satisfy the OpenAPI document
    /// requirements.
    /// - Parameter value: The variable's enum value.
    /// - Returns: A enum case declaration named by the supplied value.
    func translateVariableCase(_ value: String) -> Declaration {
        let caseName = swiftSafeName(for: value)
        if caseName == value {
            return .enumCase(name: caseName, kind: .nameOnly)
        } else {
            return .enumCase(name: caseName, kind: .nameWithRawValue(.string(value)))
        }
    }

    /// Returns a declaration of a variable enum defined in the OpenAPI document. Including
    /// a static computed property named default which returns the default defined in the
    /// document.
    /// - Parameter variable: The variable information.
    /// - Returns: An enum declaration.
    func translateServerVariable(_ variable: (key: String, value: OpenAPI.Server.Variable)) -> Declaration {
        let enumName = translateVariableToEnumName(variable)
        var casesDecls: [Declaration]

        if let enums = variable.value.enum {
            casesDecls = enums.map(translateVariableCase)
        } else {
            casesDecls = [translateVariableCase(variable.value.default)]
        }
        casesDecls.append(.commentable(
            .doc("The default variable."),
            .variable(
                accessModifier: config.access,
                isStatic: true,
                kind: .var,
                left: .identifierPattern("`\(Constants.ServerURL.defaultPropertyName)`"),
                type: .member(enumName),
                getter: [
                    .expression(
                        .return(
                            .memberAccess(.init(
                                left: .identifierPattern(enumName),
                                right: swiftSafeName(for: variable.value.default)
                            ))
                        )
                    ),
                ]
            )
        ))

        return .commentable(
            .doc("""
            The "\(variable.key)" variable defined in the OpenAPI document.

            The default value is "\(variable.value.default)".
            """),
            .enum(isFrozen: true, accessModifier: config.access, name: enumName, conformances: [TypeName.string.fullyQualifiedSwiftName], members: casesDecls)
        )
    }

    /// Returns a declaration of a namespace (enum) for a specific server and will define
    /// one enum member for each of the server's variables in the OpenAPI Document.
    /// If the server does not define variables, no declaration will be generated.
    /// - Parameters:
    ///   - index: The index of the server in the list of servers defined
    ///   in the OpenAPI document.
    ///   - server: The server variables information.
    /// - Returns: A declaration of the server variables namespace, or `nil` if no
    /// variables are declared.
    func translateServerVariables(index: Int, server: OpenAPI.Server) -> Declaration? {
        if server.variables.isEmpty {
            return nil
        }

        let typeName = translateServerVariablesEnumName(for: index)
        let variableDecls = server.variables.map(translateServerVariable)
        return .commentable(
            .doc("The variables for Server\(index + 1) defined in the OpenAPI document."),
            .enum(accessModifier: config.access, name: typeName, members: variableDecls)
        )
    }

    /// Returns a declaration of a namespace (enum) called "Variables" that
    /// defines one namespace (enum) per server URL that defines variables
    /// in the OpenAPI document. If no server URL defines variables then no
    /// declaration is generated.
    /// - Parameter servers: The servers to include in the extension.
    /// - Returns: A declaration of an enum namespace of the server URLs type.
    func translateServersVariables(_ servers: [OpenAPI.Server]) -> Declaration? {
        let variableDecls = servers.enumerated().compactMap(translateServerVariables)
        if variableDecls.isEmpty {
            return nil
        }

        return .commentable(
            .doc("Server URL variables defined in the OpenAPI document."),
            .enum(accessModifier: config.access, name: Constants.ServerURL.variablesNamespace, members: variableDecls)
        )
    }
}
