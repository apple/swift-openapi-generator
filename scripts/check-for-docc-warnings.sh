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

log "Checking required environment variables..."
test -n "${DOCC_TARGET:-}" || fatal "DOCC_TARGET unset"

CURRENT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(git -C "${CURRENT_SCRIPT_DIR}" rev-parse --show-toplevel)"

swift package --package-path "${REPO_ROOT}" plugin generate-documentation \
  --product "${DOCC_TARGET}" \
  --analyze \
  --level detailed \
  --warnings-as-errors \
  && DOCC_PLUGIN_RC=$? || DOCC_PLUGIN_RC=$?

if [ "${DOCC_PLUGIN_RC}" -ne 0 ]; then
  fatal "❌ Generating documentation produced warnings and/or errors."
  exit "${DOCC_PLUGIN_RC}"
fi

log "✅ Generated documentation with no warnings."
