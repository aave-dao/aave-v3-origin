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
	FOUNDRY_PROFILE=${chain} forge script scripts/misc/LibraryPreCompileOne.sol \
		--rpc-url ${chain} --account ${account} --slow --broadcast --gas-estimate-multiplier 150 \
		--verify --chain ${chain}
deploy-libs-two	:;
	FOUNDRY_PROFILE=${chain} forge script scripts/misc/LibraryPreCompileTwo.sol \
		--rpc-url ${chain} --account ${account} --slow --broadcast --gas-estimate-multiplier 150 \
		--verify --chain ${chain}

# STEP 1: Deploy scaled price adapters. `make deploy-scaled-price-adapter source=<PRICE_FEED_ADDRESS>`
deploy-scaled-price-adapter :;
	FOUNDRY_PROFILE=${chain} forge script scripts/misc/DeployScaledPriceAdapter.sol:DeployScaledPriceAdapter \
		--rpc-url ${chain} --account ${account} --slow --broadcast --gas-estimate-multiplier 150 \
		--verify --chain ${chain} --verifier-url ${verifier_url} \
		--sig "run(address)" ${source}

# STEP 2: Deploy Libraries
deploy-libs :
	make deploy-libs-one
	make deploy-libs-two

# STEP 3: Deploy Pool Contracts once libraries are deployed and updated on .env
deploy-v3-batched-broadcast :; 
	FOUNDRY_PROFILE=${chain} forge script scripts/DeployAaveV3MarketBatched.sol:Default \
		--rpc-url ${chain} --sender $$(cast wallet address --account ${account}) --account ${account} --slow --broadcast --gas-estimate-multiplier 150 \
		--verify --chain ${chain} --verifier-url ${verifier_url} -vvvv

# STEP 4: Deploys payload to list phase one assets. `make deploy-phase-one-payload reportPath=<PATH_TO_REPORT>`
deploy-phase-one-payload :;
	FOUNDRY_PROFILE=${chain} forge script scripts/misc/DeployHorizonPhaseOnePayload.sol:DeployHorizonPhaseOnePayload \
		--rpc-url ${chain} --account ${account} --slow --broadcast --gas-estimate-multiplier 150 \
		--verify --chain ${chain} --verifier-url ${verifier_url} \
		--sig "run(string)" ${reportPath}

# STEP 5: Deploys payload to update phase one assets. `make deploy-phase-one-update-payload`
deploy-phase-one-update-payload :;
	FOUNDRY_PROFILE=${chain} forge script scripts/misc/DeployHorizonPhaseOneUpdatePayload.sol:DeployHorizonPhaseOneUpdatePayload \
		--rpc-url ${chain} --account ${account} --slow --gas-estimate-multiplier 150 \
		--chain ${chain} --verifier etherscan \
		--sig "run()" \
		--verify --broadcast

# Deploy liquidation data provider. `make deploy-liquidation-data-provider chain=mainnet account=<account>`
deploy-liquidation-data-provider :;
	FOUNDRY_PROFILE=${chain} forge script scripts/misc/DeployLiquidationDataProvider.sol:DeployLiquidationDataProvider \
		--rpc-url ${chain} --account ${account} --slow --gas-estimate-multiplier 150 \
		--chain ${chain} --verifier-url ${verifier_url} \
		--sig "run(address,address)" ${pool} ${addressesProvider} \
		--verify --broadcast

# Deploy AToken implementation. `make deploy-atoken-impl chain=mainnet account=<account>`
deploy-atoken-impl :;
	FOUNDRY_PROFILE=${chain} forge script scripts/misc/DeployATokenImplementations.sol:DeployATokenInstance \
		--rpc-url ${chain} --account ${account} --slow $(if $(dry),,--broadcast --verify) --gas-estimate-multiplier 150 \
		--chain ${chain} --verifier-url ${verifier_url}

# Deploy RwaAToken implementation. `make deploy-rwa-atoken-impl chain=mainnet account=<account>`
deploy-rwa-atoken-impl :;
	FOUNDRY_PROFILE=${chain} forge script scripts/misc/DeployATokenImplementations.sol:DeployRwaATokenInstance \
		--rpc-url ${chain} --account ${account} --slow $(if $(dry),,--broadcast --verify) --gas-estimate-multiplier 150 \
		--chain ${chain} --verifier-url ${verifier_url}

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
