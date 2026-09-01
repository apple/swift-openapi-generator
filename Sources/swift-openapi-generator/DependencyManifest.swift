//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import Foundation
import _OpenAPIGeneratorCore

/// Version 1 of the generator-owned dependency planning contract.
struct DependencyManifest: Codable, Equatable {
    static let formatVersion = 1

    var formatVersion: Int
    var inputDigest: Digest
    var outputDigest: Digest
    var files: [File]

    struct Digest: Codable, Equatable {
        var algorithm: String
        var value: String
    }

    struct File: Codable, Equatable {
        var path: String
        var role: String
        var namespace: String?
        var dependencyLayer: Int?
        var declarationChunk: Int?
        var moduleIdentity: String
        var declarations: [String]
        var schemaDependencies: [String]
        var componentDependencies: [String]
    }

    static func make(input: Data, outputs: [InMemoryOutputFile]) -> Self {
        let sortedOutputs = outputs.sorted { $0.baseName < $1.baseName }
        var outputIdentity = Data()
        let files = sortedOutputs.map { output -> File in
            outputIdentity.append(Data(output.baseName.utf8))
            outputIdentity.append(0)
            outputIdentity.append(output.contents)
            outputIdentity.append(0)
            let metadata = output.metadata ?? fallbackMetadata(for: output.baseName)
            return File(
                path: output.baseName,
                role: metadata.role,
                namespace: metadata.namespace,
                dependencyLayer: metadata.dependencyLayer,
                declarationChunk: metadata.declarationChunk,
                moduleIdentity: metadata.moduleIdentity,
                declarations: metadata.declarations,
                schemaDependencies: metadata.schemaDependencies,
                componentDependencies: metadata.componentDependencies
            )
        }
        return .init(
            formatVersion: formatVersion,
            inputDigest: .init(algorithm: "sha256", value: SHA256Digest.hexDigest(input)),
            outputDigest: .init(algorithm: "sha256", value: SHA256Digest.hexDigest(outputIdentity)),
            files: files
        )
    }

    private static func fallbackMetadata(for fileName: String) -> GeneratedOutputFileMetadata {
        let role: String
        switch fileName {
        case OutputFileName.client.rawValue: role = "client"
        case OutputFileName.server.rawValue: role = "server"
        default: role = "generatedSource"
        }
        return .init(
            role: role,
            namespace: nil,
            dependencyLayer: nil,
            declarationChunk: nil,
            moduleIdentity: role,
            declarations: [],
            schemaDependencies: [],
            componentDependencies: []
        )
    }
}

/// A small portable SHA-256 implementation used to avoid platform-specific crypto dependencies in the generator CLI.
enum SHA256Digest {
    private static let initialHash: [UInt32] = [
        0x6a09_e667, 0xbb67_ae85, 0x3c6e_f372, 0xa54f_f53a, 0x510e_527f, 0x9b05_688c, 0x1f83_d9ab, 0x5be0_cd19,
    ]
    private static let constants: [UInt32] = [
        0x428a_2f98, 0x7137_4491, 0xb5c0_fbcf, 0xe9b5_dba5, 0x3956_c25b, 0x59f1_11f1, 0x923f_82a4, 0xab1c_5ed5,
        0xd807_aa98, 0x1283_5b01, 0x2431_85be, 0x550c_7dc3, 0x72be_5d74, 0x80de_b1fe, 0x9bdc_06a7, 0xc19b_f174,
        0xe49b_69c1, 0xefbe_4786, 0x0fc1_9dc6, 0x240c_a1cc, 0x2de9_2c6f, 0x4a74_84aa, 0x5cb0_a9dc, 0x76f9_88da,
        0x983e_5152, 0xa831_c66d, 0xb003_27c8, 0xbf59_7fc7, 0xc6e0_0bf3, 0xd5a7_9147, 0x06ca_6351, 0x1429_2967,
        0x27b7_0a85, 0x2e1b_2138, 0x4d2c_6dfc, 0x5338_0d13, 0x650a_7354, 0x766a_0abb, 0x81c2_c92e, 0x9272_2c85,
        0xa2bf_e8a1, 0xa81a_664b, 0xc24b_8b70, 0xc76c_51a3, 0xd192_e819, 0xd699_0624, 0xf40e_3585, 0x106a_a070,
        0x19a4_c116, 0x1e37_6c08, 0x2748_774c, 0x34b0_bcb5, 0x391c_0cb3, 0x4ed8_aa4a, 0x5b9c_ca4f, 0x682e_6ff3,
        0x748f_82ee, 0x78a5_636f, 0x84c8_7814, 0x8cc7_0208, 0x90be_fffa, 0xa450_6ceb, 0xbef9_a3f7, 0xc671_78f2,
    ]

    static func hexDigest(_ data: Data) -> String { digest(data).map { String(format: "%02x", $0) }.joined() }

    private static func digest(_ data: Data) -> [UInt8] {
        var bytes = Array(data)
        let bitLength = UInt64(bytes.count) * 8
        bytes.append(0x80)
        while bytes.count % 64 != 56 { bytes.append(0) }
        bytes.append(contentsOf: withUnsafeBytes(of: bitLength.bigEndian, Array.init))

        var hash = initialHash
        for blockStart in stride(from: 0, to: bytes.count, by: 64) {
            var words = Array(repeating: UInt32(0), count: 64)
            for index in 0..<16 {
                let offset = blockStart + index * 4
                words[index] =
                    UInt32(bytes[offset]) << 24 | UInt32(bytes[offset + 1]) << 16 | UInt32(bytes[offset + 2]) << 8
                    | UInt32(bytes[offset + 3])
            }
            for index in 16..<64 {
                let s0 =
                    rotateRight(words[index - 15], by: 7) ^ rotateRight(words[index - 15], by: 18)
                    ^ (words[index - 15] >> 3)
                let s1 =
                    rotateRight(words[index - 2], by: 17) ^ rotateRight(words[index - 2], by: 19)
                    ^ (words[index - 2] >> 10)
                words[index] = words[index - 16] &+ s0 &+ words[index - 7] &+ s1
            }

            var a = hash[0]
            var b = hash[1]
            var c = hash[2]
            var d = hash[3]
            var e = hash[4]
            var f = hash[5]
            var g = hash[6]
            var h = hash[7]
            for index in 0..<64 {
                let sum1 = rotateRight(e, by: 6) ^ rotateRight(e, by: 11) ^ rotateRight(e, by: 25)
                let choice = (e & f) ^ ((~e) & g)
                let temporary1 = h &+ sum1 &+ choice &+ constants[index] &+ words[index]
                let sum0 = rotateRight(a, by: 2) ^ rotateRight(a, by: 13) ^ rotateRight(a, by: 22)
                let majority = (a & b) ^ (a & c) ^ (b & c)
                let temporary2 = sum0 &+ majority
                h = g
                g = f
                f = e
                e = d &+ temporary1
                d = c
                c = b
                b = a
                a = temporary1 &+ temporary2
            }
            hash[0] &+= a
            hash[1] &+= b
            hash[2] &+= c
            hash[3] &+= d
            hash[4] &+= e
            hash[5] &+= f
            hash[6] &+= g
            hash[7] &+= h
        }
        return hash.flatMap { value in withUnsafeBytes(of: value.bigEndian, Array.init) }
    }

    private static func rotateRight(_ value: UInt32, by count: UInt32) -> UInt32 {
        (value >> count) | (value << (32 - count))
    }
}
