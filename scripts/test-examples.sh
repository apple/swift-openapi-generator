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

CURRENT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(git -C "${CURRENT_SCRIPT_DIR}" rev-parse --show-toplevel)"
TMP_DIR=$(/usr/bin/mktemp -d -p "${TMPDIR-/tmp}" "$(basename "$0").XXXXXXXXXX")

PACKAGE_PATH=${PACKAGE_PATH:-${REPO_ROOT}}
EXAMPLES_PACKAGE_PATH="${PACKAGE_PATH}/Examples"
SHARED_EXAMPLE_HARNESS_PACKAGE_PATH="${TMP_DIR}/swift-openapi-example-harness"
SHARED_PACKAGE_SCRATCH_PATH="${TMP_DIR}/swift-openapi-example-cache"
SHARED_PACKAGE_CACHE_PATH="${TMP_DIR}/swift-openapi-example-scratch"

for EXAMPLE_PACKAGE_PATH in $(find "${EXAMPLES_PACKAGE_PATH}" -maxdepth 2 -name Package.swift -type f -print0 | xargs -0 dirname | sort); do

    EXAMPLE_PACKAGE_NAME="$(basename "${EXAMPLE_PACKAGE_PATH}")"

    if [[ "${SINGLE_EXAMPLE_PACKAGE:-${EXAMPLE_PACKAGE_NAME}}" != "${EXAMPLE_PACKAGE_NAME}" ]]; then
        log "Skipping example: ${EXAMPLE_PACKAGE_NAME}"
        continue
    fi

    log "Recreating shared example harness directory: ${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}"
    rm -rf "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}"
    mkdir -v "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}"

    log "Copying example contents from ${EXAMPLE_PACKAGE_NAME} to ${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}"
    git archive HEAD "${EXAMPLE_PACKAGE_PATH}" --format tar | tar -C "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}" -xvf- --strip-components 2

    # GNU tar has --touch, but BSD tar does not, so we'll use touch directly.
    log "Updating mtime of example contents..."
    find "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}" -print0 | xargs -0 -n1 touch -m

    log "Re-overriding dependency in ${EXAMPLE_PACKAGE_NAME} to use ${PACKAGE_PATH}"
    "${SWIFT_BIN}" package \
        --package-path "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}" \
        --cache-path "${SHARED_PACKAGE_CACHE_PATH}" \
        --skip-update \
        --scratch-path "${SHARED_PACKAGE_SCRATCH_PATH}" \
        unedit swift-openapi-generator || :
    "${SWIFT_BIN}" package \
        --package-path "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}" \
        --cache-path "${SHARED_PACKAGE_CACHE_PATH}" \
        --skip-update \
        --scratch-path "${SHARED_PACKAGE_SCRATCH_PATH}" \
        edit swift-openapi-generator \
        --path "${PACKAGE_PATH}"

    log "Building example package: ${EXAMPLE_PACKAGE_NAME}"
    "${SWIFT_BIN}" build --build-tests \
        --package-path "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}" \
        --cache-path "${SHARED_PACKAGE_CACHE_PATH}" \
        --skip-update \
        --scratch-path "${SHARED_PACKAGE_SCRATCH_PATH}"
    log "✅ Successfully built the example package ${EXAMPLE_PACKAGE_NAME}."

    if [ -d "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}/Tests" ]; then
        log "Running tests for example package: ${EXAMPLE_PACKAGE_NAME}"
        "${SWIFT_BIN}" test \
            --package-path "${SHARED_EXAMPLE_HARNESS_PACKAGE_PATH}" \
            --cache-path "${SHARED_PACKAGE_CACHE_PATH}" \
            --skip-update \
            --scratch-path "${SHARED_PACKAGE_SCRATCH_PATH}"
        log "✅ Passed the tests for the example package ${EXAMPLE_PACKAGE_NAME}."
    fi
done
