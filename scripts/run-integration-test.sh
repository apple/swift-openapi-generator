#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftOpenAPIGenerator open source project
##
## Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##
set -euo pipefail

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

log "Checking required executables..."
SWIFT_BIN=${SWIFT_BIN:-$(command -v swift || xcrun -f swift)} || fatal "SWIFT_BIN unset and no swift on PATH"
JQ_BIN=${JQ_BIN:-$(command -v jq)} || fatal "JQ_BIN unset and no jq on PATH"

CURRENT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(git -C "${CURRENT_SCRIPT_DIR}" rev-parse --show-toplevel)"
TMP_DIR=$(/usr/bin/mktemp -d -p "${TMPDIR-/tmp}" "$(basename "$0").XXXXXXXXXX")

PACKAGE_PATH=${PACKAGE_PATH:-${REPO_ROOT}}

SWIFT_OPENAPI_GENERATOR_REPO_URL="${SWIFT_OPENAPI_GENERATOR_REPO_URL:-https://github.com/apple/swift-openapi-generator}"
SWIFT_OPENAPI_GENERATOR_REPO_CLONE_DIR="${TMP_DIR}/$(basename "${SWIFT_OPENAPI_GENERATOR_REPO_URL}")"
INTEGRATION_TEST_PACKAGE_PATH="${SWIFT_OPENAPI_GENERATOR_REPO_CLONE_DIR}/IntegrationTest"

log "Cloning ${SWIFT_OPENAPI_GENERATOR_REPO_URL} to ${SWIFT_OPENAPI_GENERATOR_REPO_CLONE_DIR}"
git clone --depth=1 "${SWIFT_OPENAPI_GENERATOR_REPO_URL}" "${SWIFT_OPENAPI_GENERATOR_REPO_CLONE_DIR}"

log "Extracting name for Swift package: ${PACKAGE_PATH}"
PACKAGE_NAME=$(swift package --package-path "${PACKAGE_PATH}" describe --type json | "${JQ_BIN}" -r .name)

log "Overriding dependency in ${INTEGRATION_TEST_PACKAGE_PATH} on ${PACKAGE_NAME} to use ${PACKAGE_PATH}"
swift package --package-path "${INTEGRATION_TEST_PACKAGE_PATH}" \
    edit "${PACKAGE_NAME}" --path "${PACKAGE_PATH}"

log "Building integration test package: ${INTEGRATION_TEST_PACKAGE_PATH}"
swift build --package-path "${INTEGRATION_TEST_PACKAGE_PATH}"

log "✅ Successfully built integration test package."
