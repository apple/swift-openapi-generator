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
import Synchronization

final class StreamStorage: Sendable {
    private typealias StreamType = AsyncStream<Components.Schemas.Greeting>
    private let streams: Mutex<[String: Task<Void, any Error>]>
    init() { self.streams = .init([:]) }
    private func finishedStream(id: String) {
        self.streams.withLock { streams in
            guard streams[id] != nil else { return }
            streams.removeValue(forKey: id)
        }
    }
    private func cancelStream(id: String) {
        let task: Task<Void, any Error>? = self.streams.withLock { streams in
            guard let task = streams[id] else { return nil }
            streams.removeValue(forKey: id)
            return task
        }
        guard let task else { return }
        task.cancel()
        print("Canceled stream \(id)")
    }

    private func handleTermination(
        _ termination: AsyncStream<Components.Schemas.Greeting>.Continuation.Termination,
        id: String
    ) {
        switch termination {
        case .cancelled: self.cancelStream(id: id)
        case .finished: self.finishedStream(id: id)
        @unknown default: self.finishedStream(id: id)
        }
    }

    func makeStream(input: Operations.GetGreetingsStream.Input) -> AsyncStream<Components.Schemas.Greeting> {
        let name = input.query.name ?? "Stranger"
        let id = UUID().uuidString
        print("Creating stream \(id) for name: \(name)")
        let (stream, continuation) = StreamType.makeStream()
        continuation.onTermination = { termination in self.handleTermination(termination, id: id) }
        let inputStream =
            switch input.body {
            case .applicationJsonl(let body): body.asDecodedJSONLines(of: Components.Schemas.Greeting.self)
            }
        let task = Task<Void, any Error> {
            for try await message in inputStream {
                try Task.checkCancellation()
                print("Recieved a message \(message)")
                print("Sending greeting back for \(id)")
                let greetingText = String(format: message.message, name)
                continuation.yield(.init(message: greetingText))
            }
            continuation.finish()
        }
        self.streams.withLock { streams in streams[id] = task }
        return stream
    }
}
