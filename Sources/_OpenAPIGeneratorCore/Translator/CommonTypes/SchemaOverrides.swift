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
import OpenAPIKit

/// A container of properties that can be defined at multiple levels in
/// the OpenAPI document. If a property is filled in, the value is used instead
/// of inspecting a matching property one level deeper.
///
/// One example is an OpenAPI parameter, which wraps a JSON schema. Both the
/// parameter and the schema can have a user-specified description. However if
/// both are specified, the parameter description is used, as it better matches
/// the role of the value, rather than the type of the value. However, if no
/// property description is specified, the generator uses the schema value.
struct SchemaOverrides {

    /// A Boolean value indicating whether the object is optional.
    var isOptional: Bool?

    /// A user-specified description from the OpenAPI document.
    var userDescription: String?

    /// Returns an empty overrides container.
    static var none: Self {
        .init(isOptional: nil, userDescription: nil)
    }
}
