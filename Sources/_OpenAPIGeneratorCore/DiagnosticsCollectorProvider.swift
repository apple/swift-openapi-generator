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

/// Prepares a diagnostics collector.
/// - Parameter outputPath: A file path where to persist the YAML file. If `nil`, diagnostics will be printed to stderr.
/// - Returns: A tuple containing:
///   - An instance of `DiagnosticCollector` conforming to `Sendable`.
///   - A closure to finalize the diagnostics collection
public func preparedDiagnosticsCollector(outputPath: URL?) -> (any DiagnosticCollector & Sendable, () throws -> Void) {
    let innerDiagnostics: any DiagnosticCollector & Sendable
    let finalizeDiagnostics: () throws -> Void

    if let outputPath {
        let _diagnostics = _YamlFileDiagnosticsCollector(url: outputPath)
        finalizeDiagnostics = _diagnostics.finalize
        innerDiagnostics = _diagnostics
    } else {
        innerDiagnostics = StdErrPrintingDiagnosticCollector()
        finalizeDiagnostics = {}
    }
    let diagnostics = ErrorThrowingDiagnosticCollector(upstream: innerDiagnostics)
    return (diagnostics, finalizeDiagnostics)
}
