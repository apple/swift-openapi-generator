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
import _OpenAPIGeneratorCore
import XCTest

// A diagnostic collector that fails the running test on a warning or error.
struct XCTestDiagnosticCollector: DiagnosticCollector {
    var test: XCTestCase
    var ignoredDiagnosticMessages: Set<String> = []

    func emit(_ diagnostic: Diagnostic) {
        guard !ignoredDiagnosticMessages.contains(diagnostic.message) else { return }
        print("Test emitted diagnostic: \(diagnostic.description)")
        switch diagnostic.severity {
        case .note:
            // no need to fail, just print
            break
        case .warning, .error: XCTFail("Failing with a diagnostic: \(diagnostic.description)")
        }
    }
}
