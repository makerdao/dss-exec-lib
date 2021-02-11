#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

# SOLC_FLAGS="--optimize --optimize-runs 1" dapp --use solc:0.6.11 build
dapp --use solc:0.6.11 test -v --rpc-url="$ETH_RPC_URL"
