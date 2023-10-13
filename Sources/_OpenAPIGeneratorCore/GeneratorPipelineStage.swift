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

/// A stage of a generator pipeline.
struct GeneratorPipelineStage<Input, Output> {

    /// A closure executed before the stage transition closure.
    typealias PreTransitionHook = (Input) throws -> Input

    /// A closure executed after the stage transition closure.
    typealias PostTransitionHook = (Output) throws -> Output

    /// A list of closures executed before the transition.
    private(set) var preTransitionHooks: [PreTransitionHook]

    /// A closure representing the transition from an input value to an
    /// output value.
    private(set) var transition: (Input) throws -> Output

    /// A list of closures executed after the transition.
    private(set) var postTransitionHooks: [PostTransitionHook]

    /// Runs the stage for the provided input value, returning an output
    /// value or throwing an error.
    /// - Parameter input: An input value.
    /// - Returns: An output value.
    /// - Throws: An error if an issue occurs during the stage execution.
    func run(_ input: Input) throws -> Output {
        let hookedInput = try self.preTransitionHooks.reduce(input) { try $1($0) }
        let output = try self.transition(hookedInput)
        let hookedOutput = try self.postTransitionHooks.reduce(output) { try $1($0) }
        return hookedOutput
    }
}
