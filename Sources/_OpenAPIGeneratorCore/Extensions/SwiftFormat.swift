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
import SwiftFormat
import SwiftFormatConfiguration

extension String {
    private static let configurationURL = {
        let configurationFilePath = #file
            .components(separatedBy: "/")
            .prefix(while: { $0 != "Sources" })
            .joined(separator: "/")
            .appending("/.swift-format")
        guard #available(macOS 13.0, *) else {
            return URL(fileURLWithPath: configurationFilePath)
        }
        return URL(filePath: configurationFilePath)
    }()
    /// A copy of the string formatted using swift-format.
    var swiftFormatted: Self {
        get throws {
            var formattedString = ""
            let configuration = try Configuration(contentsOf: Self.configurationURL)
            let formatter = SwiftFormatter(configuration: configuration)
            try formatter.format(
                source: self,
                assumingFileURL: nil,
                to: &formattedString
            ) { diagnostic, sourceLocation in
                print(
                    """
                    ===
                    Formatting the following code produced diagnostic at location \(sourceLocation.debugDescription) (see end):
                    ---
                    \(self.withLineNumberPrefixes)
                    ---
                    \(diagnostic.debugDescription)
                    ===
                    """
                )
                print(diagnostic)
            }
            return formattedString
        }
    }
}
