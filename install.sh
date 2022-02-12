#!/bin/bash

set -eu

TARGET_DIR="${HOME}/bin"
SRC_DIR="src"

mkdir -p "${TARGET_DIR}"
install -m 0750 "${SRC_DIR}/release.sh" "${TARGET_DIR}"

echo "Installed in ${TARGET_DIR}"
