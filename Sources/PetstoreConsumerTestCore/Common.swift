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

public enum TestError: Swift.Error, LocalizedError, CustomStringConvertible {
    case noHandlerFound(method: HTTPMethod, path: [RouterPathComponent])
    case invalidURLString(String)
    case unexpectedValue(Any)
    case unexpectedMissingRequestBody

    /// A human-readable description of the error.
    public var description: String {
        switch self {
        case .noHandlerFound(let method, let path):
            return "No handler found for method \(method.name) and path \(path.stringPath)"
        case .invalidURLString(let string):
            return "Invalid URL string: \(string)"
        case .unexpectedValue(let value):
            return "Unexpected value: \(value)"
        case .unexpectedMissingRequestBody:
            return "Unexpected missing request body"
        }
    }

    /// A localized description of the error suitable for presenting to the user.
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

public extension Array where Element == RouterPathComponent {
    var stringPath: String {
        map(\.description).joined(separator: "/")
    }
}

public extension Response {
    init(
        statusCode: Int,
        headers: [HeaderField] = [],
        encodedBody: String
    ) {
        self.init(
            statusCode: statusCode,
            headerFields: headers,
            body: Data(encodedBody.utf8)
        )
    }

    static var listPetsSuccess: Self {
        .init(
            statusCode: 200,
            headers: [
                .init(name: "content-type", value: "application/json")
            ],
            encodedBody: #"""
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

public extension Request {
    init(
        path: String,
        query: String? = nil,
        method: HTTPMethod,
        headerFields: [HeaderField] = [],
        encodedBody: String
    ) throws {
        let body = Data(encodedBody.utf8)
        self.init(
            path: path,
            query: query,
            method: method,
            headerFields: headerFields,
            body: body
        )
    }
}
