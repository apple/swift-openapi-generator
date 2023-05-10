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

public func XCTAssertEqualStringifiedData(
    _ expression1: @autoclosure () throws -> Data,
    _ expression2: @autoclosure () throws -> String,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        guard let actualString = String(data: try expression1(), encoding: .utf8) else {
            XCTFail("Data is not a valid UTF-8 string", file: file, line: line)
            return
        }
        XCTAssertEqual(actualString, try expression2(), file: file, line: line)
    } catch {
        XCTFail(error.localizedDescription, file: file, line: line)
    }
}
