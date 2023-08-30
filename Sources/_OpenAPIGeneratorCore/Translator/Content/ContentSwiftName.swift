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
import OpenAPIKit

extension FileTranslator {

    /// Returns a Swift-safe identifier used as the name of the content
    /// enum case.
    ///
    /// - Parameter contentType: The content type for which to compute the name.
    func contentSwiftName(_ contentType: ContentType) -> String {
        if config.featureFlags.contains(.multipleContentTypes) {
            switch contentType.lowercasedTypeAndSubtype {
            case "application/json": return "json"
            case "application/x-www-form-urlencoded": return "urlEncodedForm"
            case "multipart/form-data": return "multipartForm"
            case "text/plain": return "plainText"
            case "*/*": return "any"
            case "application/xml": return "xml"
            case "application/octet-stream": return "binary"
            case "text/html": return "html"
            case "application/yaml": return "yaml"
            case "text/csv": return "csv"
            case "image/png": return "png"
            case "application/pdf": return "pdf"
            case "image/jpeg": return "jpeg"
            default:
                let safedType = swiftSafeName(for: contentType.originallyCasedType)
                let safedSubtype = swiftSafeName(for: contentType.originallyCasedSubtype)
                return "\(safedType)_\(safedSubtype)"
            }
        } else {
            switch contentType.category {
            case .json: return "json"
            case .text: return "text"
            case .binary: return "binary"
            }
        }
    }
}
