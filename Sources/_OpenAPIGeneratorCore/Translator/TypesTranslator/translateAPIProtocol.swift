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

        let operations = try OperationDescription.all(
            from: paths,
            in: components,
            asSwiftSafeName: swiftSafeName
        )
        let functionDecls =
            operations
            .map(translateAPIProtocolDeclaration(operation:))

        let protocolDescription = ProtocolDescription(
            accessModifier: config.access,
            name: Constants.APIProtocol.typeName,
            conformances: Constants.APIProtocol.conformances,
            members: functionDecls
        )
        let protocolComment: Comment = .doc("A type that performs HTTP operations defined by the OpenAPI document.")

        return .commentable(
            protocolComment,
            .protocol(protocolDescription)
        )
    }

    /// Returns a declaration of a single method in the API protocol.
    ///
    /// Each method represents one HTTP operation defined in the OpenAPI
    /// document.
    /// - Parameter description: The OpenAPI operation.
    /// - Returns: A function declaration.
    func translateAPIProtocolDeclaration(
        operation description: OperationDescription
    ) -> Declaration {
        let operationComment = description.comment
        let signature = description.protocolSignatureDescription
        let function = FunctionDescription(signature: signature)
        return .commentable(
            operationComment,
            .function(function).deprecate(if: description.operation.deprecated)
        )
    }
}
