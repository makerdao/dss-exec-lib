all          :; dapp build
clean        :; dapp clean
test         :; ./test.sh
# test         :; dapp --use solc:0.6.7 test -v
deploy       :; dapp create DssExec
