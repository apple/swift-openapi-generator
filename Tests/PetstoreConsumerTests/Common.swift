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

extension Operations.ListPets.Output {
    static var success: Self { .ok(.init(headers: .init(myResponseUUID: "abcd"), body: .json([]))) }
}

extension HTTPRequest {
    /// Initializes an HTTP request with the specified path, HTTP method, and  header fields.
    ///
    /// - Parameters:
    ///   - path: The path of the HTTP request.
    ///   - method: The HTTP method (e.g., GET, POST, PUT, DELETE, etc.).
    ///   - headerFields: HTTP header fields to include in the request.
    public init(soar_path path: String, method: Method, headerFields: HTTPFields = .init()) {
        self.init(method: method, scheme: nil, authority: nil, path: path, headerFields: headerFields)
    }
}
