build        :; DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=200 dapp --use solc:0.6.12 build
clean        :; forge clean
test         :; ./test.sh $(match)
deploy       :; make build && dapp create DssExecLib
flatten      :; hevm flatten --source-file "src/DssExecLib.sol" > out/DssExecLib-flat.sol
