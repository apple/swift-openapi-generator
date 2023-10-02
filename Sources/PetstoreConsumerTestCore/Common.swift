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
import OpenAPIRuntime
import Foundation
import HTTPTypes

public enum TestError: Swift.Error, LocalizedError, CustomStringConvertible, Sendable {
    case noHandlerFound(method: HTTPRequest.Method, path: String)
    case invalidURLString(String)
    case unexpectedValue(any Sendable)
    case unexpectedMissingRequestBody

    public var description: String {
        switch self {
        case .noHandlerFound(let method, let path):
            return "No handler found for method \(method) and path \(path)"
        case .invalidURLString(let string):
            return "Invalid URL string: \(string)"
        case .unexpectedValue(let value):
            return "Unexpected value: \(value)"
        case .unexpectedMissingRequestBody:
            return "Unexpected missing request body"
        }
    }

    public var errorDescription: String? {
        description
    }
}

public extension Date {
    static var test: Date {
        Date(timeIntervalSince1970: 1_674_036_251)
    }

    static var testString: String {
        "2023-01-18T10:04:11Z"
    }
}

public extension HTTPResponse {

    func withEncodedBody(_ encodedBody: String) throws -> (HTTPResponse, HTTPBody) {
        (self, .init(encodedBody))
    }

    static var listPetsSuccess: (HTTPResponse, HTTPBody) {
        get throws {
            try Self(
                status: .ok,
                headerFields: [
                    .contentType: "application/json"
                ]
            )
            .withEncodedBody(
                #"""
                [
                  {
                    "id": 1,
                    "name": "Fluffz"
                  }
                ]
                """#
            )
        }
    }
}

public extension Data {
    var pretty: String {
        String(decoding: self, as: UTF8.self)
    }

    static var abcdString: String {
        "abcd"
    }

    static var abcd: Data {
        Data(abcdString.utf8)
    }

    static var efghString: String {
        "efgh"
    }

    static var quotedEfghString: String {
        #""efgh""#
    }

    static var efgh: Data {
        Data(efghString.utf8)
    }
}

public extension HTTPRequest {
    func withEncodedBody(_ encodedBody: String) -> (HTTPRequest, HTTPBody) {
        (self, .init(encodedBody))
    }
}
