#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

# Ensure Go-installed binaries (like Air) are on PATH.
export PATH="$(go env GOPATH)/bin:${PATH}"
exec air -c .air.toml
