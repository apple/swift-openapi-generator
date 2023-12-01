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

for EXAMPLE_PACKAGE_PATH in $(find "${EXAMPLES_PACKAGE_PATH}" -maxdepth 2 -name Package.swift -type f | xargs dirname); do

    EXAMPLE_PACKAGE_NAME=$(basename "${EXAMPLE_PACKAGE_PATH}")
    EXAMPLE_COPY_DIR="${TMP_DIR}/${EXAMPLE_PACKAGE_NAME}"
    log "Copying example ${EXAMPLE_PACKAGE_NAME} to ${EXAMPLE_COPY_DIR}"
    cp -R "${EXAMPLE_PACKAGE_PATH}" "${EXAMPLE_COPY_DIR}"

    log "Overriding dependency in ${EXAMPLE_PACKAGE_NAME} to use ${PACKAGE_PATH}"
    swift package --package-path "${EXAMPLE_COPY_DIR}" \
        edit swift-openapi-generator --path "${PACKAGE_PATH}"

    log "Building example package: ${EXAMPLE_PACKAGE_NAME}"
    swift build --package-path "${EXAMPLE_COPY_DIR}"
    log "✅ Successfully built the example package ${EXAMPLE_PACKAGE_NAME}."

    if [ -d "${EXAMPLE_COPY_DIR}/Tests" ]; then
        swift test --package-path "${EXAMPLE_COPY_DIR}"
        log "✅ Passed the tests for the example package ${EXAMPLE_PACKAGE_NAME}."
    fi
done
