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
import OpenAPIKit30

extension FileTranslator {

    /// Returns a Swift-safe identifier used as the name of the content
    /// enum case.
    ///
    /// - Parameter contentType: The content type for which to compute the name.
    func contentSwiftName(_ contentType: ContentType) -> String {
        if config.featureFlags.contains(.multipleContentTypes) {
            return "unsupported"
        } else {
            switch contentType {
            case .json:
                return "json"
            case .text:
                return "text"
            case .binary:
                return "binary"
            }
        }
    }
}
