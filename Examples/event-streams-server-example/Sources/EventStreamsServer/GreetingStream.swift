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

final class StreamStorage: @unchecked Sendable {
    private typealias StreamType = AsyncStream<Components.Schemas.Greeting>
    private var locked_streams: [String: Task<Void, any Error>]
    private let lock: NSLock
    init() {
        locked_streams = [:]
        lock = .init()
    }
    private func finishedStream(id: String) {
        lock.lock()
        defer { lock.unlock() }
        guard let task = locked_streams[id] else { return }
        locked_streams.removeValue(forKey: id)
        print("Finished stream \(id)")
    }

    private func cancelStream(id: String) {
        lock.lock()
        defer { lock.unlock() }
        guard let task = locked_streams[id] else { return }
        locked_streams.removeValue(forKey: id)
        task.cancel()
        print("Canceled stream \(id)")
    }
    func makeStream(name: String, count: Int32) -> AsyncStream<Components.Schemas.Greeting> {
        let id = UUID().uuidString
        print("Creating stream \(id) for name: \(name), count: \(count).")
        let (stream, continuation) = StreamType.makeStream()
        continuation.onTermination = { termination in
            switch termination {
            case .cancelled: self.cancelStream(id: id)
            case .finished: self.finishedStream(id: id)
            @unknown default: self.finishedStream(id: id)
            }
        }
        let task = Task<Void, any Error> {
            for i in 1...count {
                try Task.checkCancellation()
                print("Sending greeting \(i)/\(count) for \(id)")
                let greetingText = String(format: Self.templates.randomElement()!, name)
                continuation.yield(.init(message: greetingText))
                try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            }
            continuation.finish()
        }
        lock.lock()
        defer { lock.unlock() }
        locked_streams[id] = task
        return stream
    }
    private static let templates: [String] = [
        "Hello, %@!", "Good morning, %@!", "Hi, %@!", "Greetings, %@!", "Hey, %@!", "Hi there, %@!",
        "Good evening, %@!",
    ]
}
