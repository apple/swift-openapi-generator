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
    typealias ListPetsSignature = @Sendable (Operations.ListPets.Input) async throws -> Operations.ListPets.Output
    var listPetsBlock: ListPetsSignature?
    func listPets(_ input: Operations.ListPets.Input) async throws -> Operations.ListPets.Output {
        guard let block = listPetsBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias CreatePetSignature = @Sendable (Operations.CreatePet.Input) async throws -> Operations.CreatePet.Output
    var createPetBlock: CreatePetSignature?
    func createPet(_ input: Operations.CreatePet.Input) async throws -> Operations.CreatePet.Output {
        guard let block = createPetBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias CreatePetWithFormSignature = @Sendable (Operations.CreatePetWithForm.Input) async throws ->
        Operations.CreatePetWithForm.Output
    var createPetWithFormBlock: CreatePetWithFormSignature?
    func createPetWithForm(_ input: Operations.CreatePetWithForm.Input) async throws
        -> Operations.CreatePetWithForm.Output
    {
        guard let block = createPetWithFormBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias GetStatsSignature = @Sendable (Operations.GetStats.Input) async throws -> Operations.GetStats.Output
    var getStatsBlock: GetStatsSignature?
    func getStats(_ input: Operations.GetStats.Input) async throws -> Operations.GetStats.Output {
        guard let block = getStatsBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias PostStatsSignature = @Sendable (Operations.PostStats.Input) async throws -> Operations.PostStats.Output
    var postStatsBlock: PostStatsSignature?
    func postStats(_ input: Operations.PostStats.Input) async throws -> Operations.PostStats.Output {
        guard let block = postStatsBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias ProbeSignature = @Sendable (Operations.Probe.Input) async throws -> Operations.Probe.Output
    var probeBlock: ProbeSignature?
    func probe(_ input: Operations.Probe.Input) async throws -> Operations.Probe.Output {
        guard let block = probeBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias UpdatePetSignature = @Sendable (Operations.UpdatePet.Input) async throws -> Operations.UpdatePet.Output
    var updatePetBlock: UpdatePetSignature?
    func updatePet(_ input: Operations.UpdatePet.Input) async throws -> Operations.UpdatePet.Output {
        guard let block = updatePetBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }

    typealias UploadAvatarForPetSignature = @Sendable (Operations.UploadAvatarForPet.Input) async throws ->
        Operations.UploadAvatarForPet.Output
    var uploadAvatarForPetBlock: UploadAvatarForPetSignature?
    func uploadAvatarForPet(_ input: Operations.UploadAvatarForPet.Input) async throws
        -> Operations.UploadAvatarForPet.Output
    {
        guard let block = uploadAvatarForPetBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }
    typealias MultipartDownloadTypedSignature = @Sendable (Operations.MultipartDownloadTyped.Input) async throws ->
        Operations.MultipartDownloadTyped.Output
    var multipartDownloadTypedBlock: MultipartDownloadTypedSignature?
    func multipartDownloadTyped(_ input: Operations.MultipartDownloadTyped.Input) async throws
        -> Operations.MultipartDownloadTyped.Output
    {
        guard let block = multipartDownloadTypedBlock else { throw UnspecifiedBlockError() }
        return try await block(input)
    }
    typealias MultipartUploadTypedSignature = @Sendable (Operations.MultipartUploadTyped.Input) async throws ->
        Operations.MultipartUploadTyped.Output
    var multipartUploadTypedBlock: MultipartUploadTypedSignature?
    func multipartUploadTyped(_ input: Operations.MultipartUploadTyped.Input) async throws
        -> Operations.MultipartUploadTyped.Output
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
