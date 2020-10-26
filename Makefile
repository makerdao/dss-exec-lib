all          :; dapp --use solc:0.6.7 build
#build		 :; SOLC_FLAGS="--libraries src/MathLib.sol:MathLib:0x987dc24Dd903F626E8C55769BFc684871Fa28E24" dapp --use solc:0.6.7 build --extract
build		 :; dapp --use solc:0.6.7 build --extract
clean        :; dapp clean
test         :; ./test.sh
# KOVAN 0x987dc24Dd903F626E8C55769BFc684871Fa28E24
#deploy       :; SOLC_FLAGS="--optimize --optimize-runs 200 --libraries src/MathLib.sol:MathLib:0x987dc24Dd903F626E8C55769BFc684871Fa28E24" dapp --use solc:0.6.7 create DssExecLib
deploy       :; dapp --use solc:0.6.7 create DssExecLib
