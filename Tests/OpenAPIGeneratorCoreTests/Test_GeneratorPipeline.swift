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
import Foundation
import XCTest
@testable import _OpenAPIGeneratorCore

final class Test_GeneratorPipeline: Test_Core {

    func testRunGeneratorOutputsReturnsSingleFileByDefault() throws {
        let source = """
            openapi: "3.1.0"
            info:
              title: GreetingService
              version: "1.0.0"
            paths: {}
            """
        let input = InMemoryInputFile(
            absolutePath: URL(string: "openapi.yaml")!,
            contents: Data(source.utf8)
        )
        let diagnostics = AccumulatingDiagnosticCollector()
        let outputs = try runGeneratorOutputs(
            input: input,
            config: Config(mode: .types, access: .public, namingStrategy: .defensive),
            diagnostics: diagnostics
        )

        XCTAssertEqual(diagnostics.diagnostics.count, 0)
        XCTAssertEqual(outputs.map(\.baseName), ["Types.swift"])
    }

    func testPipelineRendersMultipleStructuredFiles() throws {
        let structured = StructuredSwiftRepresentation(
            files: [
                .init(
                    name: "First.swift",
                    contents: .init(
                        topComment: nil,
                        imports: nil,
                        codeBlocks: [.declaration(.enum(name: "First"))]
                    )
                ),
                .init(
                    name: "Second.swift",
                    contents: .init(
                        topComment: nil,
                        imports: nil,
                        codeBlocks: [.declaration(.enum(name: "Second"))]
                    )
                ),
            ]
        )
        let pipeline = makeGeneratorPipeline(
            parser: YamsParser(),
            translator: MultiplexTranslator(),
            renderer: { TextBasedRenderer.default },
            config: Config(mode: .types, access: .public, namingStrategy: .defensive),
            diagnostics: AccumulatingDiagnosticCollector()
        )
        let outputs = try pipeline.renderSwiftFilesStage.run(structured).files

        XCTAssertEqual(outputs.map(\.baseName), ["First.swift", "Second.swift"])
        XCTAssertTrue(String(decoding: outputs[0].contents, as: UTF8.self).contains("enum First"))
        XCTAssertFalse(String(decoding: outputs[0].contents, as: UTF8.self).contains("enum Second"))
        XCTAssertTrue(String(decoding: outputs[1].contents, as: UTF8.self).contains("enum Second"))
        XCTAssertFalse(String(decoding: outputs[1].contents, as: UTF8.self).contains("enum First"))
    }
}
