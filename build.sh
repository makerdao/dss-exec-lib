#!/usr/bin/env bash
set -e

# shellcheck disable=SC1091
source "./allow-optimize.sh"

DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=200 dapp --use solc:0.6.12 build
