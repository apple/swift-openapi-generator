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

/// A feature that can be explicitly enabled before being released.
///
/// Commonly used to get early feedback on breaking changes, before
/// they are enabled by default, which can only be done in a major version.
///
/// Once a feature is enabled unconditionally in the next major version,
/// the corresponding feature flag should be removed at the same time.
///
/// For example: a breaking feature is being built while version 0.1 is out,
/// and is hidden behind a feature flag. Once ready, the feature is
/// enabled unconditionally on main and the feature flag removed, and version
/// 0.2 is tagged. (This is for pre-1.0 versioning, would be 1.0 and 2.0 after
/// 1.0 is released.)
public enum FeatureFlag: String, Hashable, Codable, CaseIterable, Sendable {
    // needs to be here for the enum to compile
    case empty

    /// Generate shorthand APIs.
    ///
    /// This generates the following syntacic sugar API surface.
    ///
    /// #### Streamline operation input parameters
    ///
    /// The generated API protocols define one function per OpenAPI operation. These functions take
    /// a single input parameter that holds all the operation inputs (header fields, query items,
    /// cookies, body, etc.). Consequently, when making an API call, there is an additional
    /// initializer to call. This presents unnecessary ceremony, especially when calling operations
    /// with no parameters or only default parameters.
    ///
    /// ```swift
    /// // before (with parameters)
    /// _ = try await client.getGreeting(Operations.getGreeting.Input(
    ///     query: Operations.getGreeting.Input.Query(name: "Maria")
    /// ))
    ///
    /// // before (with parameters, shorthand)
    /// _ = try await client.getGreeting(.init(query: .init(name: "Maria")))
    ///
    /// // before (no parameters, shorthand)
    /// _ = try await client.getGreeting(.init()))
    /// ```
    ///
    /// When this feature flag is enabled, a protocol extension will be generated, with overload implementations that lift each of the parameters of `Input.init` as function parameters. This removes the need for users to call `Input.init`, which streamlines the API call, especially when the user does not need to provide parameters.
    ///
    /// ```swift
    /// // after (wiih parameters, shorthand)
    /// _ = try await client.getGreeting(query: .init(name: "Maria"))
    ///
    /// // after (no parameters)
    /// _ = try await client.getGreeting()
    /// ```
    ///
    /// ### Throwing getters for expected responses and content
    ///
    /// The generated `Output` type for each API operation is an enum with cases for each documented
    /// response and a case for an undocumented response. Following this pattern, the `Output.Body`
    /// is also an enum with cases for every documented content type for the response.
    ///
    /// While this API encourages users to handle all possible scenarios, it leads to ceremony when
    /// the user requires a specific response and receiving anything else is considered an error.
    /// This is especially apparent for API operations that have just a single response, e.g. `OK`,
    /// and a single content type, e.g. `application/json`.
    ///
    /// ```swift
    /// // before
    /// switch try await client.getGreeting() {
    /// case .ok(let response):
    ///     switch response.body {
    ///     case .json(let body):
    ///         print(body.message)
    ///     }
    /// case .undocumented(statusCode: _, _):
    ///     throw UnexpectedResponseError()
    /// }
    /// ```
    ///
    /// For users who wish to get an expected response or fail, they will have to define their own error type. They may also make use of `guard case let ... else { throw ... }` which reduces the code, but still presents additional ceremony.
    ///
    /// When this feature flag is enabled, a computed property is generated for each enum case. This is a read-only throwing property, which will return the associated value for the expected case, and otherwise throw a runtime error if the value is a different enum case. This allows for expressing the expected outcome as a chained operation.
    ///
    /// ```swift
    /// // after
    /// print(try await client.getGreeting().ok.body.json.message)
    /// //                     ^             ^       ^
    /// //                     |             |       `- (New) Throws if body did not conform to documented JSON.
    /// //                     |             |
    /// //                     |             `- (New) Throws if HTTP response is not 200 (OK).
    /// //                     |
    /// //                     `- (Existing) Throws if there is an error making the API call.
    /// ```
    case shorthandAPIs
}

/// A set of enabled feature flags.
public typealias FeatureFlags = Set<FeatureFlag>
