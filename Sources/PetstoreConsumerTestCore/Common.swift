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

    /// A human-readable description of the error.
    public var description: String {
        switch self {
        case .noHandlerFound(let method, let path): return "No handler found for method \(method) and path \(path)"
        case .invalidURLString(let string): return "Invalid URL string: \(string)"
        case .unexpectedValue(let value): return "Unexpected value: \(value)"
        case .unexpectedMissingRequestBody: return "Unexpected missing request body"
        }
    }

    /// A localized description of the error suitable for presenting to the user.
    public var errorDescription: String? { description }
}

public extension Date {
    static var test: Date { Date(timeIntervalSince1970: 1_674_036_251) }

    static var testString: String { "2023-01-18T10:04:11Z" }
}

public extension HTTPResponse {

    func withEncodedBody(_ encodedBody: String) throws -> (HTTPResponse, HTTPBody) { (self, .init(encodedBody)) }

    static var listPetsSuccess: (HTTPResponse, HTTPBody) {
        get throws {
            try Self(status: .ok, headerFields: [.contentType: "application/json"])
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
    var pretty: String { String(decoding: self, as: UTF8.self) }

    static var abcdString: String { "abcd" }

    static var abcd: Data { Data(abcdString.utf8) }

    static var efghString: String { "efgh" }

    static var quotedEfghString: String { #""efgh""# }

    static var efgh: Data { Data(efghString.utf8) }

    static let crlf: ArraySlice<UInt8> = [0xd, 0xa]

    static var multipartBodyString: String { String(decoding: multipartBodyAsSlice, as: UTF8.self) }

    static var multipartBodyAsSlice: [UInt8] {
        var bytes: [UInt8] = []
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; name="efficiency""#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-length: 3"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "4.2".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; name="name""#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-length: 21"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "Vitamin C and friends".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__--".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        return bytes
    }

    static var multipartBody: Data { Data(multipartBodyAsSlice) }

    static var multipartTypedBodyAsSlice: [UInt8] {
        var bytes: [UInt8] = []
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; filename="process.log"; name="log""#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-length: 35"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-type: text/plain"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"x-log-type: unstructured"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "here be logs!\nand more lines\nwheee\n".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; filename="fun.stuff"; name="keyword""#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-length: 3"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-type: text/plain"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "fun".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)

        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; filename="barfoo.txt"; name="foobar""#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-length: 0"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; name="metadata""#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-length: 42"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-type: application/json; charset=utf-8"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "{\n  \"createdAt\" : \"2023-01-18T10:04:11Z\"\n}".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; name="keyword""#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-length: 3"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: #"content-type: text/plain"#.utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "joy".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: "--".utf8)
        bytes.append(contentsOf: crlf)
        bytes.append(contentsOf: crlf)
        return bytes
    }
}

public extension HTTPRequest {
    func withEncodedBody(_ encodedBody: String) -> (HTTPRequest, HTTPBody) { (self, .init(encodedBody)) }
}
