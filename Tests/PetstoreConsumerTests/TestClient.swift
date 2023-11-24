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
import Foundation

struct TestClient: APIProtocol {
    typealias ListPetsSignature = @Sendable (Operations.listPets.Input) async throws -> Operations.listPets.Output
    var listPetsBlock: ListPetsSignature?
    func listPets(_ input: Operations.listPets.Input) async throws -> Operations.listPets.Output {
        guard let block = listPetsBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias CreatePetSignature = @Sendable (Operations.createPet.Input) async throws -> Operations.createPet.Output
    var createPetBlock: CreatePetSignature?
    func createPet(_ input: Operations.createPet.Input) async throws -> Operations.createPet.Output {
        guard let block = createPetBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias CreatePetWithFormSignature = @Sendable (Operations.createPetWithForm.Input) async throws ->
        Operations.createPetWithForm.Output
    var createPetWithFormBlock: CreatePetWithFormSignature?
    func createPetWithForm(_ input: Operations.createPetWithForm.Input) async throws
        -> Operations.createPetWithForm.Output
    {
        guard let block = createPetWithFormBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias GetStatsSignature = @Sendable (Operations.getStats.Input) async throws -> Operations.getStats.Output
    var getStatsBlock: GetStatsSignature?
    func getStats(_ input: Operations.getStats.Input) async throws -> Operations.getStats.Output {
        guard let block = getStatsBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias PostStatsSignature = @Sendable (Operations.postStats.Input) async throws -> Operations.postStats.Output
    var postStatsBlock: PostStatsSignature?
    func postStats(_ input: Operations.postStats.Input) async throws -> Operations.postStats.Output {
        guard let block = postStatsBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias ProbeSignature = @Sendable (Operations.probe.Input) async throws -> Operations.probe.Output
    var probeBlock: ProbeSignature?
    func probe(_ input: Operations.probe.Input) async throws -> Operations.probe.Output {
        guard let block = probeBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias UpdatePetSignature = @Sendable (Operations.updatePet.Input) async throws -> Operations.updatePet.Output
    var updatePetBlock: UpdatePetSignature?
    func updatePet(_ input: Operations.updatePet.Input) async throws -> Operations.updatePet.Output {
        guard let block = updatePetBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias UploadAvatarForPetSignature = @Sendable (Operations.uploadAvatarForPet.Input) async throws ->
        Operations.uploadAvatarForPet.Output
    var uploadAvatarForPetBlock: UploadAvatarForPetSignature?
    func uploadAvatarForPet(_ input: Operations.uploadAvatarForPet.Input) async throws
        -> Operations.uploadAvatarForPet.Output
    {
        guard let block = uploadAvatarForPetBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }
    typealias MultipartDownloadTypedSignature = @Sendable (Operations.multipartDownloadTyped.Input) async throws ->
        Operations.multipartDownloadTyped.Output
    var multipartDownloadTypedBlock: MultipartDownloadTypedSignature?
    func multipartDownloadTyped(_ input: Operations.multipartDownloadTyped.Input) async throws
        -> Operations.multipartDownloadTyped.Output
    {
        guard let block = multipartDownloadTypedBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }
    typealias MultipartUploadTypedSignature = @Sendable (Operations.multipartUploadTyped.Input) async throws ->
        Operations.multipartUploadTyped.Output
    var multipartUploadTypedBlock: MultipartUploadTypedSignature?
    func multipartUploadTyped(_ input: Operations.multipartUploadTyped.Input) async throws
        -> Operations.multipartUploadTyped.Output
    {
        guard let block = multipartUploadTypedBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }
}

struct UnspecifiedBlockError: Swift.Error, LocalizedError, CustomStringConvertible {
    var function: StaticString

    var description: String { "Unspecified block for \(function)" }

    var errorDescription: String? { description }

    init(function: StaticString = #function) { self.function = function }
}
