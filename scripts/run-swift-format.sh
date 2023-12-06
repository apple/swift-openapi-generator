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

FORMAT_COMMAND=(lint --strict)
for arg in "$@"; do
  if [ "$arg" == "--fix" ]; then
    FORMAT_COMMAND=(format --in-place)
  fi
done

SWIFTFORMAT_BIN=${SWIFTFORMAT_BIN:-$(command -v swift-format)} || fatal "❌ SWIFTFORMAT_BIN unset and no swift-format on PATH"

git -C "${REPO_ROOT}" ls-files -z '*.swift' \
    | grep -z -v -e 'Tests/OpenAPIGeneratorReferenceTests/Resources' \
    -e 'Sources/swift-openapi-generator/Documentation.docc' \
    -e 'Generated' \
  | xargs -0 "${SWIFTFORMAT_BIN}" "${FORMAT_COMMAND[@]}" --parallel \
  && SWIFT_FORMAT_RC=$? || SWIFT_FORMAT_RC=$?

if [ "${SWIFT_FORMAT_RC}" -ne 0 ]; then
  fatal "❌ Running swift-format produced errors.

  To fix, run the following command:

    % ./scripts/run-swift-format.sh --fix
  "
  exit "${SWIFT_FORMAT_RC}"
fi

log "✅ Ran swift-format with no errors."
