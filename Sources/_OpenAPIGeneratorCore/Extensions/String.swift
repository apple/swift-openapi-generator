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

    /// Returns a copy of the string with the first letter uppercased.
    var uppercasingFirstLetter: String { transformingFirstLetter { $0.uppercased() } }

    /// Returns a copy of the string with the first letter lowercased.
    var lowercasingFirstLetter: String { transformingFirstLetter { $0.lowercased() } }
}

fileprivate extension String {

    /// Returns a copy of the string with the first letter modified by
    /// the specified closure.
    /// - Parameter transformation: A closure that modifies the first letter.
    /// - Returns: A new string with the modified first letter, or the original string if no letter is found.
    func transformingFirstLetter<T>(_ transformation: (Character) -> T) -> String where T: StringProtocol {
        guard let firstLetterIndex = self.firstIndex(where: \.isLetter) else { return self }
        return self.replacingCharacters(
            in: firstLetterIndex..<self.index(after: firstLetterIndex),
            with: transformation(self[firstLetterIndex])
        )
    }
}
