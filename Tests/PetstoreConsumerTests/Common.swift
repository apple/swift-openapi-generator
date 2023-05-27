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

enum TestError: Swift.Error, LocalizedError, CustomStringConvertible {
    case noHandlerFound(method: HTTPMethod, path: [RouterPathComponent])
    case invalidURLString(String)
    case invalidJSONBody(String)
    case unexpectedValue(Any)
    case unexpectedMissingRequestBody

    var description: String {
        switch self {
        case .noHandlerFound(let method, let path):
            return "No handler found for method \(method.name) and path \(path.stringPath)"
        case .invalidURLString(let string):
            return "Invalid URL string: \(string)"
        case .invalidJSONBody(let body):
            return "Invalid JSON body: \(body)"
        case .unexpectedValue(let value):
            return "Unexpected value: \(value)"
        case .unexpectedMissingRequestBody:
            return "Unexpected missing request body"
        }
    }

    var errorDescription: String? {
        description
    }
}

extension Date {
    static var test: Date {
        Date(timeIntervalSince1970: 1_674_036_251)
    }

    static var testString: String {
        "2023-01-18T10:04:11Z"
    }
}

extension Array where Element == RouterPathComponent {
    var stringPath: String {
        map(\.description).joined(separator: "/")
    }
}

extension Response {
    init(
        statusCode: Int,
        headers: [HeaderField] = [],
        encodedBody: String
    ) {
        self.init(
            statusCode: statusCode,
            headerFields: headers,
            body: encodedBody.data(using: .utf8)!
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

extension Operations.listPets.Output {
    static var success: Self {
        .ok(.init(headers: .init(My_Response_UUID: "abcd"), body: .json([])))
    }
}

extension Data {
    var pretty: String {
        String(data: self, encoding: .utf8) ?? String(data: self, encoding: .ascii) ?? String(describing: self)
    }

    static var abcdString: String {
        "abcd"
    }

    static var abcd: Data {
        abcdString.data(using: .utf8)!
    }

    static var efghString: String {
        "efgh"
    }

    static var efgh: Data {
        efghString.data(using: .utf8)!
    }
}

extension Request {
    init(
        path: String,
        query: String? = nil,
        method: HTTPMethod,
        headerFields: [HeaderField] = [],
        encodedBody: String
    ) throws {
        guard let body = encodedBody.data(using: .utf8) else {
            throw TestError.invalidJSONBody(encodedBody)
        }
        self.init(
            path: path,
            query: query,
            method: method,
            headerFields: headerFields,
            body: body
        )
    }
}
