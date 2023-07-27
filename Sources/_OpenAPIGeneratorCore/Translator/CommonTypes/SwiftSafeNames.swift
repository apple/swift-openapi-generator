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
import Foundation

extension String {

    /// Returns a copy of the string modified to be a valid Swift identifier.
    ///
    /// - Parameter config: The current generator config, as the logic is
    /// conditionalized using a feature flag.
    func asSwiftSafeName(config: Config) -> String {
        guard config.featureFlags.contains(.proposal0001) else {
            return safeForSwiftCode
        }
        return proposedSafeForSwiftCode
    }
}

extension FileTranslator {

    /// Returns a copy of the string modified to be a valid Swift identifier.
    ///
    /// - Parameter string: The string to convert to be safe for Swift.
    func swiftSafeName(for string: String) -> String {
        string.asSwiftSafeName(config: config)
    }
}
