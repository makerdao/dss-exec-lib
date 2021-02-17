all          :; dapp --use solc:0.6.11 build
build        :; dapp --use solc:0.6.11 build --extract
clean        :; dapp clean
test         :; ./test.sh
deploy       :; make && dapp create DssExecLib
flatten      :; hevm flatten --source-file "src/DssExecLib.sol" > out/DssExecLib-flat.sol
