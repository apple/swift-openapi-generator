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
}

/// A set of enabled feature flags.
public typealias FeatureFlags = Set<FeatureFlag>
