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

CURRENT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NUM_CHECKS_FAILED=0
export DOCC_TARGET=swift-openapi-generator

SCRIPT_PATHS=(
  "${CURRENT_SCRIPT_DIR}/check-for-broken-symlinks.sh"
  "${CURRENT_SCRIPT_DIR}/check-for-unacceptable-language.sh"
  "${CURRENT_SCRIPT_DIR}/check-license-headers.sh"
  "${CURRENT_SCRIPT_DIR}/run-swift-format.sh"
  "${CURRENT_SCRIPT_DIR}/check-for-docc-warnings.sh"
)

for SCRIPT_PATH in "${SCRIPT_PATHS[@]}"; do
  log "Running ${SCRIPT_PATH}..."
  if ! bash "${SCRIPT_PATH}"; then
    ((NUM_CHECKS_FAILED+=1))
  fi
done

if [ "${NUM_CHECKS_FAILED}" -gt 0 ]; then
  fatal "❌ ${NUM_CHECKS_FAILED} soundness check(s) failed."
fi

log "✅ All soundness check(s) passed."
