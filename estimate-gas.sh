
#!/usr/bin/env bash

BIN=`jq '.contracts|.["src/DssExecLib.sol:DssExecLib"]|.bin' ./out/dapp.sol.json | sed 's/"//g'`
echo "DssExecLib: $(seth estimate --create 0x${BIN} "DssExecLib()")"
