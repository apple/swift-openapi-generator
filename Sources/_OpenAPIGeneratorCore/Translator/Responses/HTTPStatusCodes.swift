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

/// A namespace for known HTTP status codes.
struct HTTPStatusCodes {

    /// Returns a code-safe name for the specified HTTP status code.
    /// - Parameter code: The HTTP status code.
    static func safeName(for code: Int) -> String {
        switch code {
        case 100:
            return "`continue`"
        case 101:
            return "switchingProtocols"
        case 103:
            return "earlyHints"
        case 200:
            return "ok"
        case 201:
            return "created"
        case 202:
            return "accepted"
        case 203:
            return "nonAuthoritativeInformation"
        case 204:
            return "noContent"
        case 205:
            return "resetContent"
        case 206:
            return "partialContent"
        case 300:
            return "multipleChoices"
        case 301:
            return "movedPermanently"
        case 302:
            return "found"
        case 303:
            return "seeOther"
        case 304:
            return "notModified"
        case 307:
            return "temporaryRedirect"
        case 308:
            return "permanentRedirect"
        case 400:
            return "badRequest"
        case 401:
            return "unauthorized"
        case 403:
            return "forbidden"
        case 404:
            return "notFound"
        case 405:
            return "methodNotAllowed"
        case 406:
            return "notAcceptable"
        case 407:
            return "proxyAuthenticationRequired"
        case 408:
            return "requestTimeout"
        case 409:
            return "conflict"
        case 410:
            return "gone"
        case 411:
            return "lengthRequired"
        case 412:
            return "preconditionFailed"
        case 413:
            return "contentTooLarge"
        case 414:
            return "uriTooLong"
        case 415:
            return "unsupportedMediaType"
        case 416:
            return "rangeNotSatisfiable"
        case 417:
            return "expectationFailed"
        case 421:
            return "misdirectedRequest"
        case 422:
            return "unprocessableContent"
        case 425:
            return "tooEarly"
        case 426:
            return "upgradeRequired"
        case 428:
            return "preconditionRequired"
        case 429:
            return "tooManyRequests"
        case 431:
            return "requestHeaderFieldsTooLarge"
        case 451:
            return "unavailableForLegalReasons"
        case 500:
            return "internalServerError"
        case 501:
            return "notImplemented"
        case 502:
            return "badGateway"
        case 503:
            return "serviceUnavailable"
        case 504:
            return "gatewayTimeout"
        case 505:
            return "httpVersionNotSupported"
        case 511:
            return "networkAuthenticationRequired"
        default:
            return "code\(code)"
        }
    }
}
