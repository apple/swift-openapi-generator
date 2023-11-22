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
import OpenAPIRuntime
import HTTPTypes
import Foundation
import PetstoreConsumerTestCore

extension APIProtocol {
    func configuredServer(for serverURLString: String = "/api") throws -> TestServerTransport {
        let transport = TestServerTransport()
        try registerHandlers(
            on: transport,
            serverURL: try URL(validatingOpenAPIServerURL: serverURLString),
            configuration: .init(multipartBoundaryGenerator: .constant)
        )
        return transport
    }
}

extension TestServerTransport {

    private func findHandler(method: HTTPRequest.Method, path: String) throws -> TestServerTransport.Handler {
        guard
            let handler = registered.first(where: { operation in
                guard operation.inputs.method == method else { return false }
                guard operation.inputs.path == path else { return false }
                return true
            })
        else { throw TestError.noHandlerFound(method: method, path: path) }
        return handler.closure
    }

    var listPets: Handler { get throws { try findHandler(method: .get, path: "/api/pets") } }

    var createPet: Handler { get throws { try findHandler(method: .post, path: "/api/pets") } }

    var createPetWithForm: Handler { get throws { try findHandler(method: .post, path: "/api/pets/create") } }

    var updatePet: Handler { get throws { try findHandler(method: .patch, path: "/api/pets/{petId}") } }

    var getStats: Handler { get throws { try findHandler(method: .get, path: "/api/pets/stats") } }

    var postStats: Handler { get throws { try findHandler(method: .post, path: "/api/pets/stats") } }

    var probe: Handler { get throws { try findHandler(method: .post, path: "/api/probe/") } }

    var uploadAvatarForPet: Handler { get throws { try findHandler(method: .put, path: "/api/pets/{petId}/avatar") } }

    var multipartUploadTyped: Handler {
        get throws { try findHandler(method: .post, path: "/api/pets/multipart-typed") }
    }

    var multipartDownloadTyped: Handler {
        get throws { try findHandler(method: .get, path: "/api/pets/multipart-typed") }
    }
}
