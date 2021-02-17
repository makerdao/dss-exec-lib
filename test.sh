#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

CI=$1

# shellcheck disable=SC1091
source "./allow-optimize.sh"

if [[ "$CI" == 1 ]]; then
    dapp test -v --rpc-url="$ETH_RPC_URL"
else
    DAPP_SOLC_OPTIMIZE=true DAPP_BUILD_OPTIMIZE=1 DAPP_SOLC_OPTIMIZE_RUNS=200 dapp --use solc:0.6.11 test -v --rpc-url="$ETH_RPC_URL"
fi
