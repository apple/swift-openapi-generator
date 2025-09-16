//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Example struct to be used instead of the default generated type.
/// This illustrates how to introduce a type performing additional validation during Decoding that cannot be expressed with OpenAPI
struct CustomPrimeNumber: Codable, Hashable, RawRepresentable, Sendable {
    let rawValue: Int
    init?(rawValue: Int) {
        if !rawValue.isPrime { return nil }
        self.rawValue = rawValue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let number = try container.decode(Int.self)
        guard let value = Self(rawValue: number) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "The number is not prime.")
        }
        self = value
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

extension Int {
    fileprivate var isPrime: Bool {
        if self <= 1 { return false }
        if self <= 3 { return true }

        var i = 2
        while i * i <= self {
            if self % i == 0 { return false }
            i += 1
        }
        return true
    }
}
