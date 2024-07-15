//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension Components.Schemas.Greeting {
    package func boxed(maxBoxWidth: Int = 80) -> Self {
        // Reflow the text.
        let maxTextLength = maxBoxWidth - 4
        var reflowedLines: [Substring] = []
        for var line in message.split(whereSeparator: \.isNewline) {
            while !line.isEmpty {
                let prefix = line.prefix(maxTextLength)
                reflowedLines.append(prefix)
                line = line.dropFirst(prefix.count)
            }
        }

        // Determine the box size (might be smaller than max).
        let longestLineCount = reflowedLines.map(\.count).max()!
        let horizontalEdge = "+\(String(repeating: "–", count: longestLineCount))+"

        var boxedMessageLines: [String] = []
        boxedMessageLines.reserveCapacity(reflowedLines.count + 2)
        boxedMessageLines.append(horizontalEdge)
        for line in reflowedLines {
            boxedMessageLines.append("|\(line.padding(toLength: longestLineCount, withPad: " ", startingAt: 0))|")
        }
        boxedMessageLines.append(horizontalEdge)
        return Self(message: boxedMessageLines.joined(separator: "\n"))
    }
}
