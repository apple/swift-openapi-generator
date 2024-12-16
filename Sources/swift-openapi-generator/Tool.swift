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
import ArgumentParser

@main struct _Tool: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "swift-openapi-generator",
        abstract: "Generate Swift client and server code from an OpenAPI document",
        subcommands: [_FilterCommand.self, _GenerateCommand.self]
    )
}
