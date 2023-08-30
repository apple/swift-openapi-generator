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
import SwiftFormat
import SwiftFormatConfiguration

extension String {
    /// A copy of the string formatted using swift-format.
    var swiftFormatted: Self {
        get throws {
            var formattedString = ""
            // TODO: Should be loaded from a swift-format file that we also use to format our own code.
            var configuration = Configuration()
            configuration.rules["OrderedImports"] = false
            configuration.rules["NoAccessLevelOnExtensionDeclaration"] = false
            configuration.rules["UseLetInEveryBoundCaseVariable"] = false
            configuration.indentation = .spaces(4)
            configuration.respectsExistingLineBreaks = false
            configuration.lineBreakBeforeEachArgument = true
            configuration.lineBreakBeforeControlFlowKeywords = false
            configuration.lineBreakBeforeEachGenericRequirement = true
            configuration.lineBreakAroundMultilineExpressionChainComponents = true
            configuration.indentConditionalCompilationBlocks = false
            configuration.maximumBlankLines = 0
            let formatter = SwiftFormatter(configuration: configuration)
            try formatter.format(source: self, assumingFileURL: nil, to: &formattedString) {
                diagnostic,
                sourceLocation in
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
