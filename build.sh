#!/usr/bin/env bash
set -e

# shellcheck disable=SC1091
source "./allow-optimize.sh"

DAPP_SOLC_OPTIMIZE=true DAPP_BUILD_OPTIMIZE=1 DAPP_SOLC_OPTIMIZE_RUNS=200 dapp --use solc:0.6.11 build
