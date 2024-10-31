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

/// Constant values used in generated code, some of which refer to type names
/// in the Runtime library, so they need to be kept in sync.
enum Constants {

    /// Constants related to the library dependencies.
    enum Import {

        /// The module name of the OpenAPI runtime library.
        static let runtime: String = "OpenAPIRuntime"

        /// The module name of the HTTP types library.
        static let httpTypes: String = "HTTPTypes"
    }

    /// Constants related to the generated Swift files.
    enum File {

        /// The comment placed at the top of every generated file.
        static let topComment: String = "Generated by swift-openapi-generator, do not modify."

        /// The descriptions of modules imported by every generated file.
        static let imports: [ImportDescription] = [
            ImportDescription(moduleName: Constants.Import.runtime, spi: "Generated"),
            ImportDescription(
                moduleName: "Foundation",
                moduleTypes: ["struct Foundation.URL", "struct Foundation.Data", "struct Foundation.Date"],
                preconcurrency: .onOS(["Linux"])
            ),
        ]

        /// The descriptions of modules imported by client and server files.
        static let clientServerImports: [ImportDescription] =
            imports + [ImportDescription(moduleName: Constants.Import.httpTypes)]
    }

    /// Constants related to the OpenAPI server object.
    enum ServerURL {

        /// The name of the namespace.
        static let namespace: String = "Servers"

        /// The prefix of each generated method name.
        static let propertyPrefix: String = "server"
        /// The name of each generated static function.
        static let urlStaticFunc: String = "url"

        /// The prefix of the namespace that contains server specific variables.
        static let serverNamespacePrefix: String = "Server"

        /// Constants related to the OpenAPI server variable object.
        enum Variable {

            /// The types that the protocol conforms to.
            static let conformances: [String] = [TypeName.string.fullyQualifiedSwiftName, "Sendable"]
        }
    }

    /// Constants related to the configuration type, which is used by both
    /// the generated client and server code.
    enum Configuration {

        /// The name of the configuration type.
        static let typeName: String = "Configuration"
    }

    /// Constants related to the converter type, which is used by
    /// the generated code to convert between raw and type-safe values.
    enum Converter {

        /// The name of the converter type.
        static let typeName: String = "Converter"
    }

    /// Constants related to the generated client type.
    enum Client {

        /// The name of the client type.
        static let typeName: String = "Client"

        /// Constants related to the universal client.
        enum Universal {

            /// The name of the universal client type.
            static let typeName: String = "UniversalClient"

            /// The name of the property on the generated client
            /// that holds the universal client.
            static let propertyName: String = "client"
        }

        /// Constants related to the client transport type.
        enum Transport {

            /// The name of the client transport type.
            static let typeName: String = "any ClientTransport"
        }

        /// Constants related to the client middleware type.
        enum Middleware {

            /// The name of the client middleware type.
            static let typeName: String = "any ClientMiddleware"
        }
    }

    /// Constants related to the generated server types.
    enum Server {

        /// Constants related to the universal server.
        enum Universal {

            /// The name of the universal server type.
            static let typeName: String = "UniversalServer"

            /// The name of the generic parameter on the universal
            /// server that holds the API handler type implemented
            /// by the user.
            static let apiHandlerName: String = "APIHandler"
        }

        /// Constants related to the server transport type.
        enum Transport {

            /// The name of the server transport type.
            static let typeName: String = "any ServerTransport"
        }

        /// Constants related to the server middleware type.
        enum Middleware {

            /// The name of the server middleware type.
            static let typeName: String = "any ServerMiddleware"
        }
    }

    /// Constants related to all JSON object generated as Swift structs.
    enum ObjectStruct {

        /// The types that every struct conforms to.
        static let conformances: [String] = ["Codable", "Hashable", "Sendable"]
    }

    /// Constants related to the additional properties feature in
    /// JSON schema.
    enum AdditionalProperties { static let variableName: String = "additionalProperties" }

    /// Constants related to all generated raw enums.
    enum RawEnum {

        /// The name of the base conformance for string-based enums.
        static let baseConformanceString: String = "String"

        /// The name of the base conformance for int-based enums.
        static let baseConformanceInteger: String = "Int"

        /// The types that every enum conforms to.
        static let conformances: [String] = ["Codable", "Hashable", "Sendable", "CaseIterable"]
    }

    /// Constants related to generated oneOf enums.
    enum OneOf {
        /// The name of the discriminator variable.
        static let discriminatorName = "discriminator"
    }

    /// Constants related to the Operations namespace.
    enum Operations {

        /// The name of the namespace.
        static let namespace: String = "Operations"
    }

    /// Constants related to the generated protocol that contains one
    /// method for each OpenAPI operation.
    enum APIProtocol {

        /// The name of the generated protocol.
        static let typeName: String = "APIProtocol"

        /// The types that the protocol conforms to.
        static let conformances: [String] = ["Sendable"]
    }

    /// Constants related to each generated type that represents an OpenAPI
    /// operation.
    enum Operation {

        /// Constants related to the generated body enum, which can be used
        /// by both requests and responses.
        enum Body {

            /// The name of the generated type.
            static let typeName: String = "Body"

            /// The name of the variable used in the parent type.
            static let variableName: String = "body"

            /// The types that the body conforms to.
            static let conformances: [String] = ["Sendable", "Hashable"]
        }

        /// Constants related to every OpenAPI operation's Input struct.
        enum Input {

            /// The name of the type.
            static let typeName: String = "Input"

            /// The name of the variable used in the parent type.
            static let variableName: String = "input"

            /// The types that the Input type conforms to.
            static let conformances: [String] = ["Sendable", "Hashable"]
        }

        /// Constants related to every OpenAPI operation's Output type.
        enum Output {

            /// The name of the type.
            static let typeName: String = "Output"

            /// The types that the Output type conforms to.
            static let conformances: [String] = ["Sendable", "Hashable"]

            /// Constants related to the payload type of a response.
            enum Payload {

                /// The types that the Payload type conforms to.
                static let conformances: [String] = ["Sendable", "Hashable"]

                /// Constants related to the status code in a response.
                enum StatusCode {

                    /// The name of the variable.
                    static let variableName: String = "statusCode"
                }

                /// Constants related to the headers in a response.
                enum Headers {

                    /// The name of the type.
                    static let typeName: String = "Headers"

                    /// The name of the variable used in the parent type.
                    static let variableName: String = "headers"

                    /// The types that the Headers type conforms to.
                    static let conformances: [String] = ["Sendable", "Hashable"]
                }
            }

            /// The name of the undocumented enum case.
            static let undocumentedCaseName = "undocumented"

            /// The name of the undocumented payload type.
            static let undocumentedCaseAssociatedValueTypeName = "UndocumentedPayload"
        }

        /// Constants related to every OpenAPI operation's AcceptableContentType
        /// type.
        enum AcceptableContentType {

            /// The name of the type.
            static let typeName: String = "AcceptableContentType"

            /// The types that the AcceptableContentType type conforms to.
            static let conformances: [String] = ["AcceptableProtocol"]

            /// The name of the variable on Input given to the acceptable
            /// content types array.
            static let variableName: String = "accept"

            /// The name of the wrapper type.
            static let headerTypeName: String = "AcceptHeaderContentType"

            /// The name of the "other" case name.
            static let otherCaseName: String = "other"
        }
    }

    /// Constants related to the Components namespace.
    enum Components {

        /// The name of the namespace.
        static let namespace: String = "Components"

        /// Constants related to the Schemas namespace.
        enum Schemas {

            /// The name of the namespace.
            static let namespace: String = "Schemas"

            /// The full namespace components.
            static let components: [String] = [Constants.Components.namespace, Constants.Components.Schemas.namespace]
        }

        /// Constants related to the Parameters namespace.
        enum Parameters {

            /// The name of the namespace.
            static let namespace: String = "Parameters"

            /// Maps to `OpenAPIRuntime.ParameterStyle`.
            enum Style {

                /// The form style.
                static let form = "form"
            }
        }

        /// Constants related to the Headers namespace.
        enum Headers {

            /// The name of the namespace.
            static let namespace: String = "Headers"
        }

        /// Constants related to the Responses namespace.
        enum Responses {

            /// The name of the namespace.
            static let namespace: String = "Responses"
        }

        /// Constants related to the RequestBodies namespace.
        enum RequestBodies {

            /// The name of the namespace.
            static let namespace: String = "RequestBodies"
        }
    }

    /// Constants related to all types that conform to the Codable protocol.
    enum Codable {

        /// The name of the coding keys enum.
        static let codingKeysName: String = "CodingKeys"

        /// The types that every coding keys enum type conforms to.
        static let conformances: [String] = ["String", "CodingKey"]
    }

    /// Constants related to the coding strategy.
    enum CodingStrategy {

        /// The substring used in method names for the JSON coding strategy.
        static let json: String = "JSON"

        /// The substring used in method names for the URI coding strategy.
        static let uri: String = "URI"

        /// The substring used in method names for the binary coding strategy.
        static let binary: String = "Binary"

        /// The substring used in method names for the url encoded form coding strategy.
        static let urlEncodedForm: String = "URLEncodedForm"

        /// The substring used in method names for the multipart coding strategy.
        static let multipart: String = "Multipart"

        /// The substring used in method names for the XML coding strategy.
        static let xml: String = "XML"
    }

    /// Constants related to types used in many components.
    enum Global {

        /// The suffix of a type name generated for unnamed OpenAPI
        /// JSON schemas.
        ///
        /// Unnamed structured types are allowed in JSON Schema, but not
        /// in Swift, so the generator creates nested named types instead.
        static let inlineTypeSuffix: String = "Payload"
    }
}
