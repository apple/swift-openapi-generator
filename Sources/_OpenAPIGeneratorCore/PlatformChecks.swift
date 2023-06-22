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

// Details: https://github.com/apple/swift-openapi-generator/issues/86
#if !(os(macOS) || os(Linux))
#error("Running the generator tool itself is not supported on iOS, tvOS, and watchOS. Check that your app is not linking the generator directly. For details, check out: https://github.com/apple/swift-openapi-generator/issues/86")
#endif
