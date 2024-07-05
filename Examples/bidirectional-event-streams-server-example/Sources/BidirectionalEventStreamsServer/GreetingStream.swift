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

actor StreamStorage: Sendable {
    private typealias StreamType = AsyncStream<Components.Schemas.Greeting>
    private var streams: [String: Task<Void, any Error>] = [:]
    init() {}
    private func finishedStream(id: String) {
        guard self.streams[id] != nil else { return }
        self.streams.removeValue(forKey: id)
    }
    private func cancelStream(id: String) {
        guard let task = self.streams[id] else { return }
        self.streams.removeValue(forKey: id)
        task.cancel()
        print("Canceled stream \(id)")
    }
    func makeStream(input: Operations.getGreetingsStream.Input) -> AsyncStream<Components.Schemas.Greeting> {
        let name = input.query.name ?? "Stranger"
        let id = UUID().uuidString
        print("Creating stream \(id) for name: \(name)")
        let (stream, continuation) = StreamType.makeStream()
        continuation.onTermination = { termination in
            Task { [weak self] in
                switch termination {
                case .cancelled: await self?.cancelStream(id: id)
                case .finished: await self?.finishedStream(id: id)
                @unknown default: await self?.finishedStream(id: id)
                }
            }
        }
        let inputStream =
            switch input.body {
            case .application_jsonl(let body): body.asDecodedJSONLines(of: Components.Schemas.Greeting.self)
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
        self.streams[id] = task
        return stream
    }
}
