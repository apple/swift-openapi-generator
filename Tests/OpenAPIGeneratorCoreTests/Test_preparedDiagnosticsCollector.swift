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

final class Test_preparedDiagnosticsCollector: XCTestCase {
    func testPreparedDiagnosticsCollector() {
        let url = URL(fileURLWithPath: "/path/to/test-diagnostics.yaml")
        let collector = preparedDiagnosticsCollector(url: url)

        XCTAssertTrue(
            collector is _YamlFileDiagnosticsCollector,
            "Expected collector to be of type _YamlFileDiagnosticsCollector"
        )
    }
}
