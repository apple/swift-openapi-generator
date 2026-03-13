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
import Testing
import Foundation
@testable import _OpenAPIGeneratorCore


/// Tests that when an output path is provided, the collector factory correctly
/// instantiates the ErrorThrowingDiagnosticCollector wrapper backed by the YAML implementation.
@Test("Prepared diagnostics collector returns correct output path type")
func testPreparedDiagnosticsCollectorWithOutputPath() throws {
    let outputPath = URL(fileURLWithPath: "/path/to/diagnostics.yaml")
    let (diagnostics, _) = preparedDiagnosticsCollector(outputPath: outputPath)

    let collector = try #require(diagnostics as? ErrorThrowingDiagnosticCollector)
    
    #expect(collector.upstream is _YamlFileDiagnosticsCollector)
}


/// Verifies the fallback behavior of the diagnostics collector when no specific
/// output path is provided. Ensures that the system defaults to an error-throwing
/// collector backed by stderr printing, preventing silent loss of diagnostics.
@Test("Prepared diagnostics collector uses StdErrPrintingDiagnosticCollector when outputPath is nil")
func testPreparedDiagnosticsCollectorWithoutOutputPath() throws {
    let outputPath: URL? = nil
    let (diagnostics, _) = preparedDiagnosticsCollector(outputPath: outputPath)

    let collector = try #require(diagnostics as? ErrorThrowingDiagnosticCollector)

    #expect(collector.upstream is StdErrPrintingDiagnosticCollector)
}
