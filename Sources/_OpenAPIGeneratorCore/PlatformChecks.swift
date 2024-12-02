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
//
// When compiling for MacCatalyst, the plugin is (erroneously?) compiled with os(iOS).
#if !(os(macOS) || os(Linux) || (os(iOS) && targetEnvironment(macCatalyst)))
#error(
    "_OpenAPIGeneratorCore is only to be used by swift-openapi-generator itself—your target should not link this library or the command line tool directly."
)
#endif
