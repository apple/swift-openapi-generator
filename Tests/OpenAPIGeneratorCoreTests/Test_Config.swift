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
import OpenAPIKit
@testable import _OpenAPIGeneratorCore


// Tests the Config struct initialization, default values, and property storage
// specifically focusing on access modifiers and additional file comments configuration
@Suite("Config Tests")
struct ConfigTests {
    
    @Test("Default access modifier is internal")
    func testDefaultAccessModifier() {
        #expect(Config.defaultAccessModifier == .internal)
    }
    
    @Test("Additional file comments are stored correctly")
    func testAdditionalFileComments() {
        let config = Config(
            mode: .types,
            access: .public,
            additionalFileComments: ["swift-format-ignore-file", "swiftlint:disable all"],
            namingStrategy: .defensive
        )
        #expect(config.additionalFileComments == ["swift-format-ignore-file", "swiftlint:disable all"])
    }
    
    @Test("Additional file comments default to empty array")
    func testEmptyAdditionalFileComments() {
        let config = Config(mode: .types, access: .public, namingStrategy: .defensive)
        
        #expect(config.additionalFileComments == [])
    }
}
