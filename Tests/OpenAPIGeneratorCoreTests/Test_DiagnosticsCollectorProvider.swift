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

import XCTest
@testable import _OpenAPIGeneratorCore

final class Test_DiagnosticsCollectorProvider: XCTestCase {

    func testPreparedDiagnosticsCollectorWithOutputPath() throws {
        let outputPath = URL(fileURLWithPath: "/path/to/diagnostics.yaml")
        let (diagnostics, _) = preparedDiagnosticsCollector(outputPath: outputPath)
        XCTAssertTrue(diagnostics is ErrorThrowingDiagnosticCollector)

        if let errorThrowingCollector = diagnostics as? ErrorThrowingDiagnosticCollector {
            XCTAssertTrue(errorThrowingCollector.upstream is _YamlFileDiagnosticsCollector)
        } else {
            XCTFail("Expected diagnostics to be `ErrorThrowingDiagnosticCollector`")
        }
    }

    func testPreparedDiagnosticsCollectorWithoutOutputPath() throws {
        let outputPath: URL? = nil
        let (diagnostics, _) = preparedDiagnosticsCollector(outputPath: outputPath)
        XCTAssertTrue(diagnostics is ErrorThrowingDiagnosticCollector)
        if let errorThrowingCollector = diagnostics as? ErrorThrowingDiagnosticCollector {
            XCTAssertTrue(errorThrowingCollector.upstream is StdErrPrintingDiagnosticCollector)
        } else {
            XCTFail("Expected diagnostics to be `ErrorThrowingDiagnosticCollector`")
        }
    }
}
