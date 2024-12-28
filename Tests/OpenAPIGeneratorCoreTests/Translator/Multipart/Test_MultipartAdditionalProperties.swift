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
@preconcurrency import OpenAPIKit
@testable import _OpenAPIGeneratorCore

class Test_MultipartAdditionalProperties: XCTestCase {

    static let cases: [(Either<Bool, JSONSchema>?, MultipartAdditionalPropertiesStrategy)] = [
        (nil, .allowed), (.a(true), .any), (.a(false), .disallowed), (.b(.string), .typed(.string)),
    ]
    func test() throws {
        for (additionalProperties, expectedStrategy) in Self.cases {
            XCTAssertEqual(MultipartAdditionalPropertiesStrategy(additionalProperties), expectedStrategy)
        }
    }
}
