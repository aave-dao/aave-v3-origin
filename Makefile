# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
test   :; forge test -vvv --no-match-contract DeploymentsGasLimits
test-contract :; forge test --match-contract ${filter} -vvv
test-watch   :; forge test --watch -vvv --no-match-contract DeploymentsGasLimits

# Coverage
coverage-base :; forge coverage --fuzz-runs 50 --report lcov --no-match-coverage "(scripts|tests|deployments|mocks)"
coverage-clean :; lcov --rc derive_function_end_line=0 --remove ./lcov.info -o ./lcov.info.p \
	'src/contracts/extensions/v3-config-engine/*' \
	'src/contracts/treasury/*' \
	'src/contracts/dependencies/openzeppelin/ReentrancyGuard.sol' \
	'src/contracts/helpers/UiIncentiveDataProviderV3.sol' \
	'src/contracts/helpers/UiPoolDataProviderV3.sol' \
	'src/contracts/helpers/WalletBalanceProvider.sol' \
	'src/contracts/dependencies/*' \
	'src/contracts/helpers/AaveProtocolDataProvider.sol' \
	'src/contracts/protocol/libraries/configuration/*' \
	'src/contracts/protocol/libraries/logic/GenericLogic.sol' \
	'src/contracts/protocol/libraries/logic/ReserveLogic.sol'
coverage-report :; genhtml ./lcov.info.p -o report --branch-coverage --rc derive_function_end_line=0 --parallel
coverage-badge :; coverage=$$(awk -F '[<>]' '/headerCovTableEntryHi/{print $3}' ./report/index.html | sed 's/[^0-9.]//g' | head -n 1); \
	wget -O ./report/coverage.svg "https://img.shields.io/badge/coverage-$${coverage}%25-brightgreen"
coverage :
	make coverage-base
	make coverage-clean
	make coverage-report
	make coverage-badge


# Utilities
download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	# @npx prettier ${before} ${after} --write
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

# Deploy
deploy-libs-one	:;
	forge script scripts/misc/LibraryPreCompileOne.sol --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --sender ${SENDER} --slow --broadcast --gas-estimate-multiplier 150
deploy-libs-two	:;
	forge script scripts/misc/LibraryPreCompileTwo.sol --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --sender ${SENDER} --slow --broadcast --gas-estimate-multiplier 150

# STEP 1: Deploy Libraries
deploy-libs :
	make deploy-libs-one RPC_URL=${RPC_URL}
	npx catapulta-verify -b broadcast/LibraryPreCompileOne.sol/${CHAIN_ID}/run-latest.json
	make deploy-libs-two RPC_URL=${RPC_URL}
	npx catapulta-verify -b broadcast/LibraryPreCompileTwo.sol/${CHAIN_ID}/run-latest.json

# STEP 2: Deploy Pool Contracts once libraries are deployed and updated on .env
deploy-v3-batched-broadcast :; forge script scripts/DeployAaveV3MarketBatched.sol:Default --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --sender ${SENDER} --slow --broadcast --gas-estimate-multiplier 150

# Invariants
echidna:
	echidna tests/invariants/Tester.t.sol --contract Tester --config ./tests/invariants/_config/echidna_config.yaml --corpus-dir ./tests/invariants/_corpus/echidna/default/_data/corpus

echidna-assert:
	echidna tests/invariants/Tester.t.sol --contract Tester --test-mode assertion --config ./tests/invariants/_config/echidna_config.yaml --corpus-dir ./tests/invariants/_corpus/echidna/default/_data/corpus

echidna-explore:
	echidna tests/invariants/Tester.t.sol --contract Tester --test-mode exploration --config ./tests/invariants/_config/echidna_config.yaml --corpus-dir ./tests/invariants/_corpus/echidna/default/_data/corpus

# Medusa
medusa:
	medusa fuzz --config ./medusa.json

# Echidna Runner

HOST = power-runner
LOCAL_FOLDER = ./
REMOTE_FOLDER = ./echidna-runner
REMOTE_COMMAND = cd $(REMOTE_FOLDER)/aave-v3-origin && make echidna > process_output.log 2>&1
REMOTE_COMMAND_ASSERT = cd $(REMOTE_FOLDER)/aave-v3-origin && make echidna-assert > process_output.log 2>&1

echidna-runner:
	tar --exclude='./tests/invariants/_corpus' -czf - $(LOCAL_FOLDER) | ssh $(HOST) "export PATH=$$PATH:/root/.local/bin:/root/.foundry/bin && mkdir -p $(REMOTE_FOLDER)/aave-v3-origin && tar -xzf - -C $(REMOTE_FOLDER)/aave-v3-origin && $(REMOTE_COMMAND)"

echidna-assert-runner:
	tar --exclude='./tests/invariants/_corpus' -czf - $(LOCAL_FOLDER) | ssh $(HOST) "export PATH=$$PATH:/root/.local/bin:/root/.foundry/bin && mkdir -p $(REMOTE_FOLDER)/aave-v3-origin && tar -xzf - -C $(REMOTE_FOLDER)/aave-v3-origin && $(REMOTE_COMMAND_ASSERT)"
