#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

# SOLC_FLAGS="--optimize --optimize-runs 1" dapp --use solc:0.6.11 build
DAPP_SOLC_OPTIMIZE=true DAPP_SOLC_OPTIMIZE_RUNS=1 dapp --use solc:0.6.11 test -v --rpc
