// Generated by swift-openapi-generator, do not modify.
@_spi(Generated) import OpenAPIRuntime
#if os(Linux)
@preconcurrency import Foundation
#else
import Foundation
#endif
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
        serverURL: URL,
        configuration: Configuration = .init(),
        transport: ClientTransport,
        middlewares: [ClientMiddleware] = []
    ) {
        self.client = .init(
            serverURL: serverURL,
            configuration: configuration,
            transport: transport,
            middlewares: middlewares
        )
    }
    private var converter: Converter { client.converter }
    /// Operation `listPets` performs `GET` on `/pets`
    ///
    /// - Remark: Generated from the `listPets` operation.
    public func listPets(_ input: Operations.listPets.Input) async throws
        -> Operations.listPets.Output
    {
        try await client.send(
            input: input,
            forOperation: Operations.listPets.id,
            serializer: { input in
                let path = try converter.renderedRequestPath(template: "/pets", parameters: [])
                var request: OpenAPIRuntime.Request = .init(path: path, method: .get)
                suppressMutabilityWarning(&request)
                try converter.setQueryItemAsText(
                    in: &request,
                    name: "limit",
                    value: input.query.limit
                )
                try converter.setQueryItemAsText(
                    in: &request,
                    name: "habitat",
                    value: input.query.habitat
                )
                try converter.setQueryItemAsText(
                    in: &request,
                    name: "feeds",
                    value: input.query.feeds
                )
                try converter.setHeaderFieldAsText(
                    in: &request.headerFields,
                    name: "My-Request-UUID",
                    value: input.headers.My_Request_UUID
                )
                try converter.setQueryItemAsText(
                    in: &request,
                    name: "since",
                    value: input.query.since
                )
                try converter.setHeaderFieldAsText(
                    in: &request.headerFields,
                    name: "accept",
                    value: "application/json"
                )
                return request
            },
            deserializer: { response in
                switch response.statusCode {
                case 200:
                    let headers: Operations.listPets.Output.Ok.Headers = .init(
                        My_Response_UUID: try converter.getRequiredHeaderFieldAsText(
                            in: response.headerFields,
                            name: "My-Response-UUID",
                            as: Swift.String.self
                        ),
                        My_Tracing_Header: try converter.getOptionalHeaderFieldAsText(
                            in: response.headerFields,
                            name: "My-Tracing-Header",
                            as: Components.Headers.TracingHeader.self
                        )
                    )
                    try converter.validateContentTypeIfPresent(
                        in: response.headerFields,
                        substring: "application/json"
                    )
                    let body: Operations.listPets.Output.Ok.Body =
                        try converter.getResponseBodyAsJSON(
                            Components.Schemas.Pets.self,
                            from: response.body,
                            transforming: { value in .json(value) }
                        )
                    return .ok(.init(headers: headers, body: body))
                default:
                    let headers: Operations.listPets.Output.Default.Headers = .init()
                    try converter.validateContentTypeIfPresent(
                        in: response.headerFields,
                        substring: "application/json"
                    )
                    let body: Operations.listPets.Output.Default.Body =
                        try converter.getResponseBodyAsJSON(
                            Components.Schemas._Error.self,
                            from: response.body,
                            transforming: { value in .json(value) }
                        )
                    return .`default`(
                        statusCode: response.statusCode,
                        .init(headers: headers, body: body)
                    )
                }
            }
        )
    }
    /// Operation `createPet` performs `POST` on `/pets`
    ///
    /// - Remark: Generated from the `createPet` operation.
    public func createPet(_ input: Operations.createPet.Input) async throws
        -> Operations.createPet.Output
    {
        try await client.send(
            input: input,
            forOperation: Operations.createPet.id,
            serializer: { input in
                let path = try converter.renderedRequestPath(template: "/pets", parameters: [])
                var request: OpenAPIRuntime.Request = .init(path: path, method: .post)
                suppressMutabilityWarning(&request)
                try converter.setHeaderFieldAsJSON(
                    in: &request.headerFields,
                    name: "X-Extra-Arguments",
                    value: input.headers.X_Extra_Arguments
                )
                try converter.setHeaderFieldAsText(
                    in: &request.headerFields,
                    name: "accept",
                    value: "application/json"
                )
                request.body = try converter.setRequiredRequestBodyAsJSON(
                    input.body,
                    headerFields: &request.headerFields,
                    transforming: { wrapped in
                        switch wrapped {
                        case let .json(value):
                            return .init(
                                value: value,
                                contentType: "application/json; charset=utf-8"
                            )
                        }
                    }
                )
                return request
            },
            deserializer: { response in
                switch response.statusCode {
                case 201:
                    let headers: Operations.createPet.Output.Created.Headers = .init(
                        X_Extra_Arguments: try converter.getOptionalHeaderFieldAsJSON(
                            in: response.headerFields,
                            name: "X-Extra-Arguments",
                            as: Components.Schemas.CodeError.self
                        )
                    )
                    try converter.validateContentTypeIfPresent(
                        in: response.headerFields,
                        substring: "application/json"
                    )
                    let body: Operations.createPet.Output.Created.Body =
                        try converter.getResponseBodyAsJSON(
                            Components.Schemas.Pet.self,
                            from: response.body,
                            transforming: { value in .json(value) }
                        )
                    return .created(.init(headers: headers, body: body))
                case 400:
                    let headers: Components.Responses.ErrorBadRequest.Headers = .init(
                        X_Reason: try converter.getOptionalHeaderFieldAsText(
                            in: response.headerFields,
                            name: "X-Reason",
                            as: Swift.String.self
                        )
                    )
                    try converter.validateContentTypeIfPresent(
                        in: response.headerFields,
                        substring: "application/json"
                    )
                    let body: Components.Responses.ErrorBadRequest.Body =
                        try converter.getResponseBodyAsJSON(
                            Components.Responses.ErrorBadRequest.Body.jsonPayload.self,
                            from: response.body,
                            transforming: { value in .json(value) }
                        )
                    return .badRequest(.init(headers: headers, body: body))
                default: return .undocumented(statusCode: response.statusCode, .init())
                }
            }
        )
    }
    /// Operation `probe` performs `POST` on `/probe`
    ///
    /// - Remark: Generated from the `probe` operation.
    public func probe(_ input: Operations.probe.Input) async throws -> Operations.probe.Output {
        try await client.send(
            input: input,
            forOperation: Operations.probe.id,
            serializer: { input in
                let path = try converter.renderedRequestPath(template: "/probe", parameters: [])
                var request: OpenAPIRuntime.Request = .init(path: path, method: .post)
                suppressMutabilityWarning(&request)
                return request
            },
            deserializer: { response in
                switch response.statusCode {
                case 204:
                    let headers: Operations.probe.Output.NoContent.Headers = .init()
                    return .noContent(.init(headers: headers, body: nil))
                default: return .undocumented(statusCode: response.statusCode, .init())
                }
            }
        )
    }
    /// Operation `updatePet` performs `PATCH` on `/pets/{petId}`
    ///
    /// - Remark: Generated from the `updatePet` operation.
    public func updatePet(_ input: Operations.updatePet.Input) async throws
        -> Operations.updatePet.Output
    {
        try await client.send(
            input: input,
            forOperation: Operations.updatePet.id,
            serializer: { input in
                let path = try converter.renderedRequestPath(
                    template: "/pets/{}",
                    parameters: [input.path.petId]
                )
                var request: OpenAPIRuntime.Request = .init(path: path, method: .patch)
                suppressMutabilityWarning(&request)
                try converter.setHeaderFieldAsText(
                    in: &request.headerFields,
                    name: "accept",
                    value: "application/json"
                )
                request.body = try converter.setOptionalRequestBodyAsJSON(
                    input.body,
                    headerFields: &request.headerFields,
                    transforming: { wrapped in
                        switch wrapped {
                        case let .json(value):
                            return .init(
                                value: value,
                                contentType: "application/json; charset=utf-8"
                            )
                        }
                    }
                )
                return request
            },
            deserializer: { response in
                switch response.statusCode {
                case 204:
                    let headers: Operations.updatePet.Output.NoContent.Headers = .init()
                    return .noContent(.init(headers: headers, body: nil))
                case 400:
                    let headers: Operations.updatePet.Output.BadRequest.Headers = .init()
                    try converter.validateContentTypeIfPresent(
                        in: response.headerFields,
                        substring: "application/json"
                    )
                    let body: Operations.updatePet.Output.BadRequest.Body =
                        try converter.getResponseBodyAsJSON(
                            Operations.updatePet.Output.BadRequest.Body.jsonPayload.self,
                            from: response.body,
                            transforming: { value in .json(value) }
                        )
                    return .badRequest(.init(headers: headers, body: body))
                default: return .undocumented(statusCode: response.statusCode, .init())
                }
            }
        )
    }
    /// Operation `uploadAvatarForPet` performs `PUT` on `/pets/{petId}/avatar`
    ///
    /// - Remark: Generated from the `uploadAvatarForPet` operation.
    public func uploadAvatarForPet(_ input: Operations.uploadAvatarForPet.Input) async throws
        -> Operations.uploadAvatarForPet.Output
    {
        try await client.send(
            input: input,
            forOperation: Operations.uploadAvatarForPet.id,
            serializer: { input in
                let path = try converter.renderedRequestPath(
                    template: "/pets/{}/avatar",
                    parameters: [input.path.petId]
                )
                var request: OpenAPIRuntime.Request = .init(path: path, method: .put)
                suppressMutabilityWarning(&request)
                try converter.setHeaderFieldAsText(
                    in: &request.headerFields,
                    name: "accept",
                    value: "application/octet-stream, application/json, text/plain"
                )
                request.body = try converter.setRequiredRequestBodyAsBinary(
                    input.body,
                    headerFields: &request.headerFields,
                    transforming: { wrapped in
                        switch wrapped {
                        case let .binary(value):
                            return .init(value: value, contentType: "application/octet-stream")
                        }
                    }
                )
                return request
            },
            deserializer: { response in
                switch response.statusCode {
                case 200:
                    let headers: Operations.uploadAvatarForPet.Output.Ok.Headers = .init()
                    try converter.validateContentTypeIfPresent(
                        in: response.headerFields,
                        substring: "application/octet-stream"
                    )
                    let body: Operations.uploadAvatarForPet.Output.Ok.Body =
                        try converter.getResponseBodyAsBinary(
                            Foundation.Data.self,
                            from: response.body,
                            transforming: { value in .binary(value) }
                        )
                    return .ok(.init(headers: headers, body: body))
                case 412:
                    let headers: Operations.uploadAvatarForPet.Output.PreconditionFailed.Headers =
                        .init()
                    try converter.validateContentTypeIfPresent(
                        in: response.headerFields,
                        substring: "application/json"
                    )
                    let body: Operations.uploadAvatarForPet.Output.PreconditionFailed.Body =
                        try converter.getResponseBodyAsJSON(
                            Swift.String.self,
                            from: response.body,
                            transforming: { value in .json(value) }
                        )
                    return .preconditionFailed(.init(headers: headers, body: body))
                case 500:
                    let headers: Operations.uploadAvatarForPet.Output.InternalServerError.Headers =
                        .init()
                    try converter.validateContentTypeIfPresent(
                        in: response.headerFields,
                        substring: "text/plain"
                    )
                    let body: Operations.uploadAvatarForPet.Output.InternalServerError.Body =
                        try converter.getResponseBodyAsText(
                            Swift.String.self,
                            from: response.body,
                            transforming: { value in .text(value) }
                        )
                    return .internalServerError(.init(headers: headers, body: body))
                default: return .undocumented(statusCode: response.statusCode, .init())
                }
            }
        )
    }
}
