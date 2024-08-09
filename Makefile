# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
test   :; forge test -vvv --no-match-contract DeploymentsGasLimits
test-contract :; forge test --match-contract ${filter} -vvv
test-watch   :; forge test --watch -vvv --no-match-contract DeploymentsGasLimits
coverage :; forge coverage --report lcov && \
	lcov --remove ./lcov.info -o ./lcov.info.p \
	'scripts/*' \
	'tests/*' \
	'src/deployments/*' \
	'src/periphery/contracts/v3-config-engine/*' \
	'src/periphery/contracts/treasury/*' \
	'src/periphery/contracts/dependencies/openzeppelin/ReentrancyGuard.sol' \
	'src/periphery/contracts/misc/UiIncentiveDataProviderV3.sol' \
	'src/periphery/contracts/misc/UiPoolDataProviderV3.sol' \
	'src/periphery/contracts/misc/WalletBalanceProvider.sol' \
	'src/periphery/contracts/mocks/*' \
	'src/core/contracts/mocks/*' \
	'src/core/contracts/dependencies/*' \
	'src/core/contracts/misc/AaveProtocolDataProvider.sol' \
	'src/core/contracts/protocol/libraries/configuration/*' \
	'src/core/contracts/protocol/libraries/logic/GenericLogic.sol' \
	'src/core/contracts/protocol/libraries/logic/ReserveLogic.sol' \
	&& genhtml ./lcov.info.p -o report --branch-coverage \
	&& coverage=$$(awk -F '[<>]' '/headerCovTableEntryHi/{print $3}' ./report/index.html | sed 's/[^0-9.]//g' | head -n 1); \
	wget -O ./report/coverage.svg "https://img.shields.io/badge/coverage-$${coverage}%25-brightgreen"

# Utilities
download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	@npx prettier ${before} ${after} --write
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

diff-arbitrum-zksync :;
	mkdir -p diffs/ARBITRUM_ZKSYNC
	ts-node ./diff.ts ARBITRUM ZKSYNC
