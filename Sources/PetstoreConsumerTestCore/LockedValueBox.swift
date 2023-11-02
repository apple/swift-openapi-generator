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

public final class LockedValueBox<Value>: @unchecked Sendable {
    private var value: Value
    private let lock: NSLock
    public init(value: Value) {
        self.value = value
        let lock = NSLock()
        lock.name = "LockedValueBox of \(type(of: value))"
        self.lock = lock
    }
    public func withLocked<R>(_ work: (inout Value) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try work(&value)
    }
}
