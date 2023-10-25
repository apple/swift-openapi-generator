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
extension Int {
    /// Returns the digits for the number using the specified radix.
    /// - Parameter radix: The radix used to format the integer.
    /// - Returns: An array of digits.
    func digits(radix: Self = 10) -> [Self] {
        sequence(state: self) { quotient in
            guard quotient > 0 else { return nil }
            let division = quotient.quotientAndRemainder(dividingBy: radix)
            quotient = division.quotient
            return division.remainder
        }
        .reversed()
    }
}

extension String {
    /// A copy of the string with each line prefixed with a line number.
    ///
    /// The prefix is rendered as `N: `, starting from `N: 1`.
    var withLineNumberPrefixes: String {
        let lines = self.split(separator: "\n")
        let lineNumberCols = lines.count.digits().count
        return lines.enumerated()
            .map { (i, line) in "\(String(i+1).padding(toLength: lineNumberCols, withPad: " ", startingAt: 0)): \(line)"
            }
            .joined(separator: "\n")
    }
}
