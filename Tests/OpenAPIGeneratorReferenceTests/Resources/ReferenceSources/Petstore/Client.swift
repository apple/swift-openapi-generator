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
/// Service for managing pet metadata.
///
/// Because why not.
public struct Client: APIProtocol {
    /// The underlying HTTP client.
    private let client: UniversalClient
    /// Creates a new client.
    /// - Parameters:
    ///   - serverURL: The server URL that the client connects to. Any server
    ///   URLs defined in the OpenAPI document are available as static methods
    ///   on the ``Servers`` type.
    ///   - configuration: A set of configuration values for the client.
    ///   - transport: A transport that performs HTTP operations.
    ///   - middlewares: A list of middlewares to call before the transport.
    public init(
        serverURL: Foundation.URL,
        configuration: Configuration = .init(),
        transport: any ClientTransport,
        middlewares: [any ClientMiddleware] = []
    ) {
        self.client = .init(
            serverURL: serverURL,
            configuration: configuration,
            transport: transport,
            middlewares: middlewares
        )
    }
    private var converter: Converter {
        client.converter
    }
    /// List all pets
    ///
    /// You can fetch
    /// all the pets here
    ///
    /// - Remark: HTTP `GET /pets`.
    /// - Remark: Generated from `#/paths//pets/get(listPets)`.
    public func listPets(_ input: Operations.listPets.Input) async throws -> Operations.listPets.Output {
        try await client.send(
            input: input,
            forOperation: Operations.listPets.id,
            serializer: { input in
                let path = try converter.renderedPath(
                    template: "/pets",
                    parameters: []
                )
                var request: HTTPTypes.HTTPRequest = .init(
                    soar_path: path,
                    method: .get
                )
                suppressMutabilityWarning(&request)
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "limit",
                    value: input.query.limit
                )
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "habitat",
                    value: input.query.habitat
                )
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "feeds",
                    value: input.query.feeds
                )
                try converter.setHeaderFieldAsURI(
                    in: &request.headerFields,
                    name: "My-Request-UUID",
                    value: input.headers.My_hyphen_Request_hyphen_UUID
                )
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "since",
                    value: input.query.since
                )
                converter.setAcceptHeader(
                    in: &request.headerFields,
                    contentTypes: input.headers.accept
                )
                return (request, nil)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 200:
                    let headers: Operations.listPets.Output.Ok.Headers = .init(
                        My_hyphen_Response_hyphen_UUID: try converter.getRequiredHeaderFieldAsURI(
                            in: response.headerFields,
                            name: "My-Response-UUID",
                            as: Swift.String.self
                        ),
                        My_hyphen_Tracing_hyphen_Header: try converter.getOptionalHeaderFieldAsURI(
                            in: response.headerFields,
                            name: "My-Tracing-Header",
                            as: Components.Headers.TracingHeader.self
                        )
                    )
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.listPets.Output.Ok.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/json"
                    ) {
                        body = try await converter.getResponseBodyAsJSON(
                            Components.Schemas.Pets.self,
                            from: responseBody,
                            transforming: { value in
                                .json(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .ok(.init(
                        headers: headers,
                        body: body
                    ))
                default:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.listPets.Output.Default.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/json"
                    ) {
                        body = try await converter.getResponseBodyAsJSON(
                            Components.Schemas._Error.self,
                            from: responseBody,
                            transforming: { value in
                                .json(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .`default`(
                        statusCode: response.status.code,
                        .init(body: body)
                    )
                }
            }
        )
    }
    /// Create a pet
    ///
    /// - Remark: HTTP `POST /pets`.
    /// - Remark: Generated from `#/paths//pets/post(createPet)`.
    public func createPet(_ input: Operations.createPet.Input) async throws -> Operations.createPet.Output {
        try await client.send(
            input: input,
            forOperation: Operations.createPet.id,
            serializer: { input in
                let path = try converter.renderedPath(
                    template: "/pets",
                    parameters: []
                )
                var request: HTTPTypes.HTTPRequest = .init(
                    soar_path: path,
                    method: .post
                )
                suppressMutabilityWarning(&request)
                try converter.setHeaderFieldAsJSON(
                    in: &request.headerFields,
                    name: "X-Extra-Arguments",
                    value: input.headers.X_hyphen_Extra_hyphen_Arguments
                )
                converter.setAcceptHeader(
                    in: &request.headerFields,
                    contentTypes: input.headers.accept
                )
                let body: OpenAPIRuntime.HTTPBody?
                switch input.body {
                case let .json(value):
                    body = try converter.setRequiredRequestBodyAsJSON(
                        value,
                        headerFields: &request.headerFields,
                        contentType: "application/json; charset=utf-8"
                    )
                }
                return (request, body)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 201:
                    let headers: Operations.createPet.Output.Created.Headers = .init(X_hyphen_Extra_hyphen_Arguments: try converter.getOptionalHeaderFieldAsJSON(
                        in: response.headerFields,
                        name: "X-Extra-Arguments",
                        as: Components.Schemas.CodeError.self
                    ))
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.createPet.Output.Created.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/json"
                    ) {
                        body = try await converter.getResponseBodyAsJSON(
                            Components.Schemas.Pet.self,
                            from: responseBody,
                            transforming: { value in
                                .json(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .created(.init(
                        headers: headers,
                        body: body
                    ))
                case 400 ... 499:
                    let headers: Components.Responses.ErrorBadRequest.Headers = .init(X_hyphen_Reason: try converter.getOptionalHeaderFieldAsURI(
                        in: response.headerFields,
                        name: "X-Reason",
                        as: Swift.String.self
                    ))
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Components.Responses.ErrorBadRequest.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/json"
                    ) {
                        body = try await converter.getResponseBodyAsJSON(
                            Components.Responses.ErrorBadRequest.Body.jsonPayload.self,
                            from: responseBody,
                            transforming: { value in
                                .json(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .clientError(
                        statusCode: response.status.code,
                        .init(
                            headers: headers,
                            body: body
                        )
                    )
                default:
                    return .undocumented(
                        statusCode: response.status.code,
                        .init()
                    )
                }
            }
        )
    }
    /// Create a pet using a url form
    ///
    /// - Remark: HTTP `POST /pets/create`.
    /// - Remark: Generated from `#/paths//pets/create/post(createPetWithForm)`.
    public func createPetWithForm(_ input: Operations.createPetWithForm.Input) async throws -> Operations.createPetWithForm.Output {
        try await client.send(
            input: input,
            forOperation: Operations.createPetWithForm.id,
            serializer: { input in
                let path = try converter.renderedPath(
                    template: "/pets/create",
                    parameters: []
                )
                var request: HTTPTypes.HTTPRequest = .init(
                    soar_path: path,
                    method: .post
                )
                suppressMutabilityWarning(&request)
                let body: OpenAPIRuntime.HTTPBody?
                switch input.body {
                case let .urlEncodedForm(value):
                    body = try converter.setRequiredRequestBodyAsURLEncodedForm(
                        value,
                        headerFields: &request.headerFields,
                        contentType: "application/x-www-form-urlencoded"
                    )
                }
                return (request, body)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 204:
                    return .noContent(.init())
                default:
                    return .undocumented(
                        statusCode: response.status.code,
                        .init()
                    )
                }
            }
        )
    }
    /// - Remark: HTTP `GET /pets/stats`.
    /// - Remark: Generated from `#/paths//pets/stats/get(getStats)`.
    public func getStats(_ input: Operations.getStats.Input) async throws -> Operations.getStats.Output {
        try await client.send(
            input: input,
            forOperation: Operations.getStats.id,
            serializer: { input in
                let path = try converter.renderedPath(
                    template: "/pets/stats",
                    parameters: []
                )
                var request: HTTPTypes.HTTPRequest = .init(
                    soar_path: path,
                    method: .get
                )
                suppressMutabilityWarning(&request)
                converter.setAcceptHeader(
                    in: &request.headerFields,
                    contentTypes: input.headers.accept
                )
                return (request, nil)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 200:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.getStats.Output.Ok.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/json"
                    ) {
                        body = try await converter.getResponseBodyAsJSON(
                            Components.Schemas.PetStats.self,
                            from: responseBody,
                            transforming: { value in
                                .json(value)
                            }
                        )
                    } else if try converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "text/plain"
                    ) {
                        body = try converter.getResponseBodyAsBinary(
                            OpenAPIRuntime.HTTPBody.self,
                            from: responseBody,
                            transforming: { value in
                                .plainText(value)
                            }
                        )
                    } else if try converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/octet-stream"
                    ) {
                        body = try converter.getResponseBodyAsBinary(
                            OpenAPIRuntime.HTTPBody.self,
                            from: responseBody,
                            transforming: { value in
                                .binary(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .ok(.init(body: body))
                default:
                    return .undocumented(
                        statusCode: response.status.code,
                        .init()
                    )
                }
            }
        )
    }
    /// - Remark: HTTP `POST /pets/stats`.
    /// - Remark: Generated from `#/paths//pets/stats/post(postStats)`.
    public func postStats(_ input: Operations.postStats.Input) async throws -> Operations.postStats.Output {
        try await client.send(
            input: input,
            forOperation: Operations.postStats.id,
            serializer: { input in
                let path = try converter.renderedPath(
                    template: "/pets/stats",
                    parameters: []
                )
                var request: HTTPTypes.HTTPRequest = .init(
                    soar_path: path,
                    method: .post
                )
                suppressMutabilityWarning(&request)
                let body: OpenAPIRuntime.HTTPBody?
                switch input.body {
                case let .json(value):
                    body = try converter.setRequiredRequestBodyAsJSON(
                        value,
                        headerFields: &request.headerFields,
                        contentType: "application/json; charset=utf-8"
                    )
                case let .plainText(value):
                    body = try converter.setRequiredRequestBodyAsBinary(
                        value,
                        headerFields: &request.headerFields,
                        contentType: "text/plain"
                    )
                case let .binary(value):
                    body = try converter.setRequiredRequestBodyAsBinary(
                        value,
                        headerFields: &request.headerFields,
                        contentType: "application/octet-stream"
                    )
                }
                return (request, body)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 202:
                    return .accepted(.init())
                default:
                    return .undocumented(
                        statusCode: response.status.code,
                        .init()
                    )
                }
            }
        )
    }
    /// - Remark: HTTP `POST /probe/`.
    /// - Remark: Generated from `#/paths//probe//post(probe)`.
    public func probe(_ input: Operations.probe.Input) async throws -> Operations.probe.Output {
        try await client.send(
            input: input,
            forOperation: Operations.probe.id,
            serializer: { input in
                let path = try converter.renderedPath(
                    template: "/probe/",
                    parameters: []
                )
                var request: HTTPTypes.HTTPRequest = .init(
                    soar_path: path,
                    method: .post
                )
                suppressMutabilityWarning(&request)
                return (request, nil)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 204:
                    return .noContent(.init())
                default:
                    return .undocumented(
                        statusCode: response.status.code,
                        .init()
                    )
                }
            }
        )
    }
    /// Update just a specific property of an existing pet. Nothing is updated if no request body is provided.
    ///
    /// - Remark: HTTP `PATCH /pets/{petId}`.
    /// - Remark: Generated from `#/paths//pets/{petId}/patch(updatePet)`.
    public func updatePet(_ input: Operations.updatePet.Input) async throws -> Operations.updatePet.Output {
        try await client.send(
            input: input,
            forOperation: Operations.updatePet.id,
            serializer: { input in
                let path = try converter.renderedPath(
                    template: "/pets/{}",
                    parameters: [
                        input.path.petId
                    ]
                )
                var request: HTTPTypes.HTTPRequest = .init(
                    soar_path: path,
                    method: .patch
                )
                suppressMutabilityWarning(&request)
                converter.setAcceptHeader(
                    in: &request.headerFields,
                    contentTypes: input.headers.accept
                )
                let body: OpenAPIRuntime.HTTPBody?
                switch input.body {
                case .none:
                    body = nil
                case let .json(value):
                    body = try converter.setOptionalRequestBodyAsJSON(
                        value,
                        headerFields: &request.headerFields,
                        contentType: "application/json; charset=utf-8"
                    )
                }
                return (request, body)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 204:
                    return .noContent(.init())
                case 400:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.updatePet.Output.BadRequest.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/json"
                    ) {
                        body = try await converter.getResponseBodyAsJSON(
                            Operations.updatePet.Output.BadRequest.Body.jsonPayload.self,
                            from: responseBody,
                            transforming: { value in
                                .json(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .badRequest(.init(body: body))
                default:
                    return .undocumented(
                        statusCode: response.status.code,
                        .init()
                    )
                }
            }
        )
    }
    /// Upload an avatar
    ///
    /// - Remark: HTTP `PUT /pets/{petId}/avatar`.
    /// - Remark: Generated from `#/paths//pets/{petId}/avatar/put(uploadAvatarForPet)`.
    public func uploadAvatarForPet(_ input: Operations.uploadAvatarForPet.Input) async throws -> Operations.uploadAvatarForPet.Output {
        try await client.send(
            input: input,
            forOperation: Operations.uploadAvatarForPet.id,
            serializer: { input in
                let path = try converter.renderedPath(
                    template: "/pets/{}/avatar",
                    parameters: [
                        input.path.petId
                    ]
                )
                var request: HTTPTypes.HTTPRequest = .init(
                    soar_path: path,
                    method: .put
                )
                suppressMutabilityWarning(&request)
                converter.setAcceptHeader(
                    in: &request.headerFields,
                    contentTypes: input.headers.accept
                )
                let body: OpenAPIRuntime.HTTPBody?
                switch input.body {
                case let .binary(value):
                    body = try converter.setRequiredRequestBodyAsBinary(
                        value,
                        headerFields: &request.headerFields,
                        contentType: "application/octet-stream"
                    )
                }
                return (request, body)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 200:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.uploadAvatarForPet.Output.Ok.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/octet-stream"
                    ) {
                        body = try converter.getResponseBodyAsBinary(
                            OpenAPIRuntime.HTTPBody.self,
                            from: responseBody,
                            transforming: { value in
                                .binary(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .ok(.init(body: body))
                case 412:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.uploadAvatarForPet.Output.PreconditionFailed.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "application/json"
                    ) {
                        body = try await converter.getResponseBodyAsJSON(
                            Swift.String.self,
                            from: responseBody,
                            transforming: { value in
                                .json(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .preconditionFailed(.init(body: body))
                case 500:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.uploadAvatarForPet.Output.InternalServerError.Body
                    if try contentType == nil || converter.isMatchingContentType(
                        received: contentType,
                        expectedRaw: "text/plain"
                    ) {
                        body = try converter.getResponseBodyAsBinary(
                            OpenAPIRuntime.HTTPBody.self,
                            from: responseBody,
                            transforming: { value in
                                .plainText(value)
                            }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .internalServerError(.init(body: body))
                default:
                    return .undocumented(
                        statusCode: response.status.code,
                        .init()
                    )
                }
            }
        )
    }
}
