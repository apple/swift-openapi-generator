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

// Emit a compiler error if this library is linked with a target in an adopter
// project.
// This is only done for platforms where the linkage was most likely added
// erroneously (for platforms which can't be used as development hosts).
#if (os(iOS) && !targetEnvironment(macCatalyst)) || os(tvOS) || os(watchOS) || os(visionOS)
#error(
    "_OpenAPIGeneratorCore is only to be used by swift-openapi-generator itself—your target should not link this library or the command line tool directly."
)
#endif
