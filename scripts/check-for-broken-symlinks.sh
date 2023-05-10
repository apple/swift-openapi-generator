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
REPO_ROOT="$(git -C "${CURRENT_SCRIPT_DIR}" rev-parse --show-toplevel)"

log "Checking for broken symlinks..."
NUM_BROKEN_SYMLINKS=0
while read -r -d '' file; do
  if ! test -e "${REPO_ROOT}/${file}"; then
    error "Broken symlink: ${file}"
    ((NUM_BROKEN_SYMLINKS++))
  fi
done < <(git -C "${REPO_ROOT}" ls-files -z)

if [ "${NUM_BROKEN_SYMLINKS}" -gt 0 ]; then
  fatal "❌ Found ${NUM_BROKEN_SYMLINKS} symlinks."
fi

log "✅ Found 0 symlinks."
