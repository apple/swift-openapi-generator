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

/// A translator for the generated common types.
///
/// Types.swift is the Swift file containing all the reusable types from
/// the "Components" section in the OpenAPI document, as well as all of the
/// namespaces for each OpenAPI operation, including their Input and Output
/// types.
///
/// Types generated in this file are depended on by both Client.swift and
/// Server.swift.
struct TypesFileTranslator: FileTranslator {

    var config: Config
    var diagnostics: any DiagnosticCollector
    var components: OpenAPI.Components

    func translateFile(parsedOpenAPI: ParsedOpenAPIRepresentation) throws -> StructuredSwiftRepresentation {

        let doc = parsedOpenAPI

        let topComment: Comment = .inline(Constants.File.topComment)

        let imports = Constants.File.imports + config.additionalImports.map { ImportDescription(moduleName: $0) }

        let apiProtocol = try translateAPIProtocol(doc.paths)

        let apiProtocolExtension = try translateAPIProtocolExtension(doc.paths)

        let serversDecl = translateServers(doc.servers)

        // TODO: Here, go through all schema + encoding pairs, and verify (using a deep comparison, not refs)
        // that we only ever get one encoding for every schema. Otherwise emit a diagnostic warning
        // and say we'll skip any request/response body schemas that have a mismatched encoding.
        // Or use the first one, whichever is easier.
        
        let components = try translateComponents(doc.components)

        let operationDescriptions = try OperationDescription.all(
            from: doc.paths,
            in: doc.components,
            asSwiftSafeName: swiftSafeName
        )
        let operations = try translateOperations(operationDescriptions)

        let typesFile = FileDescription(
            topComment: topComment,
            imports: imports,
            codeBlocks: [
                .declaration(apiProtocol), .declaration(apiProtocolExtension), .declaration(serversDecl), components,
                operations,
            ]
        )

        return StructuredSwiftRepresentation(file: .init(name: GeneratorMode.types.outputFileName, contents: typesFile))
    }
}
