all          :; dapp --use solc:0.6.7 build
build		 :; dapp --use solc:0.6.7 build --extract
clean        :; dapp clean
test         :; ./test.sh
# test         :; dapp --use solc:0.6.7 test -v
deploy       :; dapp create DssExec
