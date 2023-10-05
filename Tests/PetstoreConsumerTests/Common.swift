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
import HTTPTypes

extension Operations.listPets.Output {
    static var success: Self {
        .ok(.init(headers: .init(My_hyphen_Response_hyphen_UUID: "abcd"), body: .json([])))
    }
}

extension HTTPRequest {
    public init(soar_path path: String, method: Method, headerFields: HTTPFields = .init()) {
        self.init(method: method, scheme: nil, authority: nil, path: path, headerFields: headerFields)
    }
}
