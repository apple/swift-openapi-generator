// Generated by swift-openapi-generator, do not modify.
@_spi(Generated) import OpenAPIRuntime
#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
@preconcurrency import struct Foundation.Date
#else
import struct Foundation.URL
import struct Foundation.Data
import struct Foundation.Date
#endif
import HTTPTypes
extension APIProtocol {
    /// Registers each operation handler with the provided transport.
    /// - Parameters:
    ///   - transport: A transport to which to register the operation handlers.
    ///   - serverURL: A URL used to determine the path prefix for registered
    ///   request handlers.
    ///   - configuration: A set of configuration values for the server.
    ///   - middlewares: A list of middlewares to call before the handler.
    public func registerHandlers(
        on transport: any ServerTransport,
        serverURL: URL = .defaultOpenAPIServerURL,
        configuration: Configuration = .init(),
        middlewares: [any ServerMiddleware] = []
    ) throws {
        let server = UniversalServer(
            serverURL: serverURL,
            handler: self,
            configuration: configuration,
            middlewares: middlewares
        )
        try transport.register(
            { try await server.listPets(request: $0, body: $1, metadata: $2) },
            method: .get,
            path: server.apiPathComponentsWithServerPrefix("/pets")
        )
        try transport.register(
            { try await server.createPet(request: $0, body: $1, metadata: $2) },
            method: .post,
            path: server.apiPathComponentsWithServerPrefix("/pets")
        )
        try transport.register(
            { try await server.getStats(request: $0, body: $1, metadata: $2) },
            method: .get,
            path: server.apiPathComponentsWithServerPrefix("/pets/stats")
        )
        try transport.register(
            { try await server.postStats(request: $0, body: $1, metadata: $2) },
            method: .post,
            path: server.apiPathComponentsWithServerPrefix("/pets/stats")
        )
        try transport.register(
            { try await server.probe(request: $0, body: $1, metadata: $2) },
            method: .post,
            path: server.apiPathComponentsWithServerPrefix("/probe/")
        )
        try transport.register(
            { try await server.updatePet(request: $0, body: $1, metadata: $2) },
            method: .patch,
            path: server.apiPathComponentsWithServerPrefix("/pets/{petId}")
        )
        try transport.register(
            { try await server.uploadAvatarForPet(request: $0, body: $1, metadata: $2) },
            method: .put,
            path: server.apiPathComponentsWithServerPrefix("/pets/{petId}/avatar")
        )
    }
}
fileprivate extension UniversalServer where APIHandler: APIProtocol {
    /// List all pets
    ///
    /// You can fetch
    /// all the pets here
    ///
    /// - Remark: HTTP `GET /pets`.
    /// - Remark: Generated from `#/paths//pets/get(listPets)`.
    func listPets(request: HTTPRequest, body: HTTPBody?, metadata: ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    ) {
        try await handle(
            request: request,
            requestBody: body,
            metadata: metadata,
            forOperation: Operations.listPets.id,
            using: { APIHandler.listPets($0) },
            deserializer: { request, requestBody, metadata in
                let query: Operations.listPets.Input.Query = .init(
                    limit: try converter.getOptionalQueryItemAsURI(
                        in: request.soar_query,
                        style: .form,
                        explode: true,
                        name: "limit",
                        as: Swift.Int32.self
                    ),
                    habitat: try converter.getOptionalQueryItemAsURI(
                        in: request.soar_query,
                        style: .form,
                        explode: true,
                        name: "habitat",
                        as: Operations.listPets.Input.Query.habitatPayload.self
                    ),
                    feeds: try converter.getOptionalQueryItemAsURI(
                        in: request.soar_query,
                        style: .form,
                        explode: true,
                        name: "feeds",
                        as: Operations.listPets.Input.Query.feedsPayload.self
                    ),
                    since: try converter.getOptionalQueryItemAsURI(
                        in: request.soar_query,
                        style: .form,
                        explode: true,
                        name: "since",
                        as: Components.Parameters.query_period_born_hyphen_since.self
                    )
                )
                let headers: Operations.listPets.Input.Headers = .init(
                    My_hyphen_Request_hyphen_UUID: try converter.getOptionalHeaderFieldAsURI(
                        in: request.headerFields,
                        name: "My-Request-UUID",
                        as: Swift.String.self
                    ),
                    accept: try converter.extractAcceptHeaderIfPresent(in: request.headerFields)
                )
                return Operations.listPets.Input(query: query, headers: headers)
            },
            serializer: { output, request in
                switch output {
                case let .ok(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 200)
                    suppressMutabilityWarning(&response)
                    try converter.setHeaderFieldAsURI(
                        in: &response.headerFields,
                        name: "My-Response-UUID",
                        value: value.headers.My_hyphen_Response_hyphen_UUID
                    )
                    try converter.setHeaderFieldAsURI(
                        in: &response.headerFields,
                        name: "My-Tracing-Header",
                        value: value.headers.My_hyphen_Tracing_hyphen_Header
                    )
                    let body: HTTPBody
                    switch value.body {
                    case let .json(value):
                        try converter.validateAcceptIfPresent("application/json", in: request.headerFields)
                        body = try converter.setResponseBodyAsJSON(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (response, body)
                case let .`default`(statusCode, value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: statusCode)
                    suppressMutabilityWarning(&response)
                    let body: HTTPBody
                    switch value.body {
                    case let .json(value):
                        try converter.validateAcceptIfPresent("application/json", in: request.headerFields)
                        body = try converter.setResponseBodyAsJSON(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (response, body)
                }
            }
        )
    }
    /// Create a pet
    ///
    /// - Remark: HTTP `POST /pets`.
    /// - Remark: Generated from `#/paths//pets/post(createPet)`.
    func createPet(request: HTTPRequest, body: HTTPBody?, metadata: ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    ) {
        try await handle(
            request: request,
            requestBody: body,
            metadata: metadata,
            forOperation: Operations.createPet.id,
            using: { APIHandler.createPet($0) },
            deserializer: { request, requestBody, metadata in
                let headers: Operations.createPet.Input.Headers = .init(
                    X_hyphen_Extra_hyphen_Arguments: try converter.getOptionalHeaderFieldAsJSON(
                        in: request.headerFields,
                        name: "X-Extra-Arguments",
                        as: Components.Schemas.CodeError.self
                    ),
                    accept: try converter.extractAcceptHeaderIfPresent(in: request.headerFields)
                )
                let contentType = converter.extractContentTypeIfPresent(in: request.headerFields)
                let body: Operations.createPet.Input.Body
                if try contentType == nil
                    || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                {
                    body = try await converter.getRequiredRequestBodyAsJSON(
                        Components.Schemas.CreatePetRequest.self,
                        from: requestBody,
                        transforming: { value in .json(value) }
                    )
                } else {
                    throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                }
                return Operations.createPet.Input(headers: headers, body: body)
            },
            serializer: { output, request in
                switch output {
                case let .created(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 201)
                    suppressMutabilityWarning(&response)
                    try converter.setHeaderFieldAsJSON(
                        in: &response.headerFields,
                        name: "X-Extra-Arguments",
                        value: value.headers.X_hyphen_Extra_hyphen_Arguments
                    )
                    let body: HTTPBody
                    switch value.body {
                    case let .json(value):
                        try converter.validateAcceptIfPresent("application/json", in: request.headerFields)
                        body = try converter.setResponseBodyAsJSON(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (response, body)
                case let .clientError(statusCode, value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: statusCode)
                    suppressMutabilityWarning(&response)
                    try converter.setHeaderFieldAsURI(
                        in: &response.headerFields,
                        name: "X-Reason",
                        value: value.headers.X_hyphen_Reason
                    )
                    let body: HTTPBody
                    switch value.body {
                    case let .json(value):
                        try converter.validateAcceptIfPresent("application/json", in: request.headerFields)
                        body = try converter.setResponseBodyAsJSON(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (response, body)
                case let .undocumented(statusCode, _): return (.init(soar_statusCode: statusCode), nil)
                }
            }
        )
    }
    /// - Remark: HTTP `GET /pets/stats`.
    /// - Remark: Generated from `#/paths//pets/stats/get(getStats)`.
    func getStats(request: HTTPRequest, body: HTTPBody?, metadata: ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    ) {
        try await handle(
            request: request,
            requestBody: body,
            metadata: metadata,
            forOperation: Operations.getStats.id,
            using: { APIHandler.getStats($0) },
            deserializer: { request, requestBody, metadata in
                let headers: Operations.getStats.Input.Headers = .init(
                    accept: try converter.extractAcceptHeaderIfPresent(in: request.headerFields)
                )
                return Operations.getStats.Input(headers: headers)
            },
            serializer: { output, request in
                switch output {
                case let .ok(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 200)
                    suppressMutabilityWarning(&response)
                    let body: HTTPBody
                    switch value.body {
                    case let .json(value):
                        try converter.validateAcceptIfPresent("application/json", in: request.headerFields)
                        body = try converter.setResponseBodyAsJSON(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    case let .plainText(value):
                        try converter.validateAcceptIfPresent("text/plain", in: request.headerFields)
                        body = try converter.setResponseBodyAsBinary(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "text/plain"
                        )
                    case let .binary(value):
                        try converter.validateAcceptIfPresent("application/octet-stream", in: request.headerFields)
                        body = try converter.setResponseBodyAsBinary(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/octet-stream"
                        )
                    }
                    return (response, body)
                case let .undocumented(statusCode, _): return (.init(soar_statusCode: statusCode), nil)
                }
            }
        )
    }
    /// - Remark: HTTP `POST /pets/stats`.
    /// - Remark: Generated from `#/paths//pets/stats/post(postStats)`.
    func postStats(request: HTTPRequest, body: HTTPBody?, metadata: ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    ) {
        try await handle(
            request: request,
            requestBody: body,
            metadata: metadata,
            forOperation: Operations.postStats.id,
            using: { APIHandler.postStats($0) },
            deserializer: { request, requestBody, metadata in
                let contentType = converter.extractContentTypeIfPresent(in: request.headerFields)
                let body: Operations.postStats.Input.Body
                if try contentType == nil
                    || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                {
                    body = try await converter.getRequiredRequestBodyAsJSON(
                        Components.Schemas.PetStats.self,
                        from: requestBody,
                        transforming: { value in .json(value) }
                    )
                } else if try converter.isMatchingContentType(received: contentType, expectedRaw: "text/plain") {
                    body = try converter.getRequiredRequestBodyAsBinary(
                        OpenAPIRuntime.HTTPBody.self,
                        from: requestBody,
                        transforming: { value in .plainText(value) }
                    )
                } else if try converter.isMatchingContentType(
                    received: contentType,
                    expectedRaw: "application/octet-stream"
                ) {
                    body = try converter.getRequiredRequestBodyAsBinary(
                        OpenAPIRuntime.HTTPBody.self,
                        from: requestBody,
                        transforming: { value in .binary(value) }
                    )
                } else {
                    throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                }
                return Operations.postStats.Input(body: body)
            },
            serializer: { output, request in
                switch output {
                case let .accepted(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 202)
                    suppressMutabilityWarning(&response)
                    return (response, nil)
                case let .undocumented(statusCode, _): return (.init(soar_statusCode: statusCode), nil)
                }
            }
        )
    }
    /// - Remark: HTTP `POST /probe/`.
    /// - Remark: Generated from `#/paths//probe//post(probe)`.
    func probe(request: HTTPRequest, body: HTTPBody?, metadata: ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    ) {
        try await handle(
            request: request,
            requestBody: body,
            metadata: metadata,
            forOperation: Operations.probe.id,
            using: { APIHandler.probe($0) },
            deserializer: { request, requestBody, metadata in return Operations.probe.Input() },
            serializer: { output, request in
                switch output {
                case let .noContent(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 204)
                    suppressMutabilityWarning(&response)
                    return (response, nil)
                case let .undocumented(statusCode, _): return (.init(soar_statusCode: statusCode), nil)
                }
            }
        )
    }
    /// Update just a specific property of an existing pet. Nothing is updated if no request body is provided.
    ///
    /// - Remark: HTTP `PATCH /pets/{petId}`.
    /// - Remark: Generated from `#/paths//pets/{petId}/patch(updatePet)`.
    func updatePet(request: HTTPRequest, body: HTTPBody?, metadata: ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    ) {
        try await handle(
            request: request,
            requestBody: body,
            metadata: metadata,
            forOperation: Operations.updatePet.id,
            using: { APIHandler.updatePet($0) },
            deserializer: { request, requestBody, metadata in
                let path: Operations.updatePet.Input.Path = .init(
                    petId: try converter.getPathParameterAsURI(
                        in: metadata.pathParameters,
                        name: "petId",
                        as: Swift.Int64.self
                    )
                )
                let headers: Operations.updatePet.Input.Headers = .init(
                    accept: try converter.extractAcceptHeaderIfPresent(in: request.headerFields)
                )
                let contentType = converter.extractContentTypeIfPresent(in: request.headerFields)
                let body: Components.RequestBodies.UpdatePetRequest?
                if try contentType == nil
                    || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                {
                    body = try await converter.getOptionalRequestBodyAsJSON(
                        Components.RequestBodies.UpdatePetRequest.jsonPayload.self,
                        from: requestBody,
                        transforming: { value in .json(value) }
                    )
                } else {
                    throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                }
                return Operations.updatePet.Input(path: path, headers: headers, body: body)
            },
            serializer: { output, request in
                switch output {
                case let .noContent(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 204)
                    suppressMutabilityWarning(&response)
                    return (response, nil)
                case let .badRequest(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 400)
                    suppressMutabilityWarning(&response)
                    let body: HTTPBody
                    switch value.body {
                    case let .json(value):
                        try converter.validateAcceptIfPresent("application/json", in: request.headerFields)
                        body = try converter.setResponseBodyAsJSON(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (response, body)
                case let .undocumented(statusCode, _): return (.init(soar_statusCode: statusCode), nil)
                }
            }
        )
    }
    /// Upload an avatar
    ///
    /// - Remark: HTTP `PUT /pets/{petId}/avatar`.
    /// - Remark: Generated from `#/paths//pets/{petId}/avatar/put(uploadAvatarForPet)`.
    func uploadAvatarForPet(request: HTTPRequest, body: HTTPBody?, metadata: ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    ) {
        try await handle(
            request: request,
            requestBody: body,
            metadata: metadata,
            forOperation: Operations.uploadAvatarForPet.id,
            using: { APIHandler.uploadAvatarForPet($0) },
            deserializer: { request, requestBody, metadata in
                let path: Operations.uploadAvatarForPet.Input.Path = .init(
                    petId: try converter.getPathParameterAsURI(
                        in: metadata.pathParameters,
                        name: "petId",
                        as: Components.Parameters.path_period_petId.self
                    )
                )
                let headers: Operations.uploadAvatarForPet.Input.Headers = .init(
                    accept: try converter.extractAcceptHeaderIfPresent(in: request.headerFields)
                )
                let contentType = converter.extractContentTypeIfPresent(in: request.headerFields)
                let body: Operations.uploadAvatarForPet.Input.Body
                if try contentType == nil
                    || converter.isMatchingContentType(received: contentType, expectedRaw: "application/octet-stream")
                {
                    body = try converter.getRequiredRequestBodyAsBinary(
                        OpenAPIRuntime.HTTPBody.self,
                        from: requestBody,
                        transforming: { value in .binary(value) }
                    )
                } else {
                    throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                }
                return Operations.uploadAvatarForPet.Input(path: path, headers: headers, body: body)
            },
            serializer: { output, request in
                switch output {
                case let .ok(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 200)
                    suppressMutabilityWarning(&response)
                    let body: HTTPBody
                    switch value.body {
                    case let .binary(value):
                        try converter.validateAcceptIfPresent("application/octet-stream", in: request.headerFields)
                        body = try converter.setResponseBodyAsBinary(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/octet-stream"
                        )
                    }
                    return (response, body)
                case let .preconditionFailed(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 412)
                    suppressMutabilityWarning(&response)
                    let body: HTTPBody
                    switch value.body {
                    case let .json(value):
                        try converter.validateAcceptIfPresent("application/json", in: request.headerFields)
                        body = try converter.setResponseBodyAsJSON(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (response, body)
                case let .internalServerError(value):
                    suppressUnusedWarning(value)
                    var response = HTTPResponse(soar_statusCode: 500)
                    suppressMutabilityWarning(&response)
                    let body: HTTPBody
                    switch value.body {
                    case let .plainText(value):
                        try converter.validateAcceptIfPresent("text/plain", in: request.headerFields)
                        body = try converter.setResponseBodyAsBinary(
                            value,
                            headerFields: &response.headerFields,
                            contentType: "text/plain"
                        )
                    }
                    return (response, body)
                case let .undocumented(statusCode, _): return (.init(soar_statusCode: statusCode), nil)
                }
            }
        )
    }
}
