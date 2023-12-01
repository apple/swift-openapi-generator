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
JQ_BIN=${JQ_BIN:-$(command -v jq)} || fatal "JQ_BIN unset and no jq on PATH"

CURRENT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(git -C "${CURRENT_SCRIPT_DIR}" rev-parse --show-toplevel)"
TMP_DIR=$(/usr/bin/mktemp -d -p "${TMPDIR-/tmp}" "$(basename "$0").XXXXXXXXXX")

PACKAGE_PATH=${PACKAGE_PATH:-${REPO_ROOT}}
EXAMPLES_PACKAGE_PATH="${PACKAGE_PATH}/Examples"

# TODO: do this in tmpdir

for EXAMPLE_PACKAGE_PATH in $(find "${EXAMPLES_PACKAGE_PATH}" -name Package.swift -type f -maxdepth 2 | xargs dirname); do

    log "Overriding dependency in ${EXAMPLE_PACKAGE_PATH} to use ${PACKAGE_PATH}"
    swift package --package-path "${EXAMPLE_PACKAGE_PATH}" \
        edit swift-openapi-generator --path "${PACKAGE_PATH}"

    log "Building example package: ${EXAMPLE_PACKAGE_PATH}"
    swift build --package-path "${EXAMPLE_PACKAGE_PATH}"
    log "✅ Successfully built the example package ${EXAMPLE_PACKAGE_PATH}."

    if [ -d "${EXAMPLE_PACKAGE_PATH}/Tests" ]; then
        swift test --package-path "${EXAMPLE_PACKAGE_PATH}"
        log "✅ Passed the tests for the example package ${EXAMPLE_PACKAGE_PATH}."
    fi
done
