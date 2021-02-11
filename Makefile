all          :; DAPP_SOLC_OPTIMIZE=true DAPP_SOLC_OPTIMIZE_RUNS=200 dapp --use solc:0.6.11 build
build		 :; DAPP_SOLC_OPTIMIZE=true DAPP_SOLC_OPTIMIZE_RUNS=200 dapp --use solc:0.6.11 build --extract
clean        :; dapp clean
test         :; ./test.sh
deploy       :; make && dapp --use solc:0.6.11 create DssExecLib
