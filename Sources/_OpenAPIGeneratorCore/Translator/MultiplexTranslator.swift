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

/// A translator that inspects the generator configuration and delegates
/// the code generation logic to the appropriate translator.
struct MultiplexTranslator: TranslatorProtocol {
    func translate(parsedOpenAPI: ParsedOpenAPIRepresentation, config: Config, diagnostics: any DiagnosticCollector)
        throws -> StructuredSwiftRepresentation
    {
        let translator: any FileTranslator
        switch config.mode {
        case .types:
            translator = TypesFileTranslator(
                config: config,
                diagnostics: diagnostics,
                components: parsedOpenAPI.components
            )
        case .client:
            translator = ClientFileTranslator(
                config: config,
                diagnostics: diagnostics,
                components: parsedOpenAPI.components
            )
        case .server:
            translator = ServerFileTranslator(
                config: config,
                diagnostics: diagnostics,
                components: parsedOpenAPI.components
            )
        }
        return try translator.translateFile(parsedOpenAPI: parsedOpenAPI)
    }
}
