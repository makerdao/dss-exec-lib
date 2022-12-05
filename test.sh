#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(cast chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

export FOUNDRY_OPTIMIZER=true
export FOUNDRY_OPTIMIZER_RUNS=200

if [[ -z "$1" ]]; then
    forge test --use "0.6.12" --fork-url "$ETH_RPC_URL" -vv --force
else
    forge test --use "0.6.12" --fork-url "$ETH_RPC_URL" --match "$1" -vvv --force
fi
