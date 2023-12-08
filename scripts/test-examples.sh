#!/usr/bin/env bash
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
SHARED_SCRATCH_PATH="${TMP_DIR}/scratch"
SHARED_CACHE_PATH="${TMP_DIR}/cache"

for EXAMPLE_PACKAGE_PATH in $(find "${EXAMPLES_PACKAGE_PATH}" -maxdepth 2 -name Package.swift -type f -print0 | xargs -0 dirname); do

    EXAMPLE_PACKAGE_NAME="$(basename "${EXAMPLE_PACKAGE_PATH}")"
    EXAMPLE_COPY_DIR="${TMP_DIR}/${EXAMPLE_PACKAGE_NAME}"

    if [[ "${SINGLE_EXAMPLE_PACKAGE:-${EXAMPLE_PACKAGE_NAME}}" != "${EXAMPLE_PACKAGE_NAME}" ]]; then
        log "Skipping example: ${EXAMPLE_PACKAGE_NAME}"
        continue
    fi

    log "Copying example ${EXAMPLE_PACKAGE_NAME} to ${EXAMPLE_COPY_DIR}"
    mkdir "${EXAMPLE_COPY_DIR}"
    git archive HEAD "${EXAMPLE_PACKAGE_PATH}" --format tar | tar -C "${EXAMPLE_COPY_DIR}" -xvf- --strip-components 2

    log "Overriding dependency in ${EXAMPLE_PACKAGE_NAME} to use ${PACKAGE_PATH}"
    "${SWIFT_BIN}" package \
        --package-path "${EXAMPLE_COPY_DIR}" \
        --scratch-path "${SHARED_SCRATCH_PATH}" \
        --cache-path "${SHARED_CACHE_PATH}" \
        edit swift-openapi-generator \
        --path "${PACKAGE_PATH}"

    log "Building example package: ${EXAMPLE_PACKAGE_NAME}"
    "${SWIFT_BIN}" build \
        --package-path "${EXAMPLE_COPY_DIR}" \
        --scratch-path "${SHARED_SCRATCH_PATH}" \
        --cache-path "${SHARED_CACHE_PATH}"
    log "✅ Successfully built the example package ${EXAMPLE_PACKAGE_NAME}."

    if [ -d "${EXAMPLE_COPY_DIR}/Tests" ]; then
        log "Running tests for example package: ${EXAMPLE_PACKAGE_NAME}"
        "${SWIFT_BIN}" test \
            --package-path "${EXAMPLE_COPY_DIR}" \
            --scratch-path "${SHARED_SCRATCH_PATH}" \
            --cache-path "${SHARED_CACHE_PATH}"
        log "✅ Passed the tests for the example package ${EXAMPLE_PACKAGE_NAME}."
    fi

    log "Unediting dependency in ${EXAMPLE_PACKAGE_NAME}"
    "${SWIFT_BIN}" package \
        --package-path "${EXAMPLE_COPY_DIR}" \
        --scratch-path "${SHARED_SCRATCH_PATH}" \
        --cache-path "${SHARED_CACHE_PATH}" \
        unedit swift-openapi-generator

    log "Deleting example ${EXAMPLE_PACKAGE_NAME} at ${EXAMPLE_COPY_DIR}"
    rm -rf "${EXAMPLE_COPY_DIR}"
done

log "Deleting cache directories"
rm -rf "${SHARED_SCRATCH_PATH}"
rm -rf "${SHARED_CACHE_PATH}"
