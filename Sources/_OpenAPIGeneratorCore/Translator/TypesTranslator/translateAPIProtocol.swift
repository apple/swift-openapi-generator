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

    /// Returns a declaration of the API protocol, which contains one method
    /// per HTTP operation defined in the OpenAPI document.
    /// - Parameter paths: The paths object from the OpenAPI document.
    /// - Returns: A protocol declaration.
    /// - Throws: If `paths` contains any references.
    func translateAPIProtocol(_ paths: OpenAPI.PathItem.Map) throws -> Declaration {

        let operations = try OperationDescription.all(from: paths, in: components, context: context)
        let functionDecls = operations.map(translateAPIProtocolDeclaration(operation:))

        let protocolDescription = ProtocolDescription(
            accessModifier: config.access,
            name: Constants.APIProtocol.typeName,
            conformances: Constants.APIProtocol.conformances,
            members: functionDecls
        )
        let protocolComment: Comment = .doc("A type that performs HTTP operations defined by the OpenAPI document.")

        return .commentable(protocolComment, .protocol(protocolDescription))
    }

    /// Returns an extension to the `APIProtocol` protocol, with some syntactic sugar APIs.
    func translateAPIProtocolExtension(_ paths: OpenAPI.PathItem.Map) throws -> Declaration {
        let operations = try OperationDescription.all(from: paths, in: components, context: context)

        // This looks for all initializers in the operation input struct and creates a flattened function.
        let flattenedOperations = try operations.flatMap { operation in
            guard case let .commentable(_, .struct(input)) = try translateOperationInput(operation) else {
                fatalError()
            }
            return input.members.compactMap { member -> Declaration? in
                guard case let .commentable(_, .function(initializer)) = member,
                    case .initializer = initializer.signature.kind
                else { return nil }
                let function = FunctionDescription(
                    accessModifier: config.access,
                    kind: .function(name: operation.methodName),
                    parameters: initializer.signature.parameters,
                    keywords: [.async, .throws],
                    returnType: .identifierType(operation.outputTypeName),
                    body: [
                        .try(
                            .await(
                                .identifierPattern(operation.methodName)
                                    .call([
                                        FunctionArgumentDescription(
                                            label: nil,
                                            expression: .identifierType(operation.inputTypeName)
                                                .call(
                                                    initializer.signature.parameters.map { parameter in
                                                        guard let label = parameter.label else { preconditionFailure() }
                                                        return FunctionArgumentDescription(
                                                            label: label,
                                                            expression: .identifierPattern(label)
                                                        )
                                                    }
                                                )
                                        )
                                    ])
                            )
                        )
                    ]
                )
                if operation.operation.deprecated {
                    return .commentable(operation.comment, .deprecated(.init(), .function(function)))
                } else {
                    return .commentable(operation.comment, .function(function))
                }
            }
        }

        return .commentable(
            .doc("Convenience overloads for operation inputs."),
            .extension(ExtensionDescription(onType: Constants.APIProtocol.typeName, declarations: flattenedOperations))
        )
    }

    /// Returns a declaration of a single method in the API protocol.
    ///
    /// Each method represents one HTTP operation defined in the OpenAPI
    /// document.
    /// - Parameter description: The OpenAPI operation.
    /// - Returns: A function declaration.
    func translateAPIProtocolDeclaration(operation description: OperationDescription) -> Declaration {
        let operationComment = description.comment
        let signature = description.protocolSignatureDescription
        let function = FunctionDescription(signature: signature)
        return .commentable(operationComment, .function(function).deprecate(if: description.operation.deprecated))
    }
}
