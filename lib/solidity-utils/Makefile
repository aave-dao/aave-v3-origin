# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes --via-ir
test   :; forge test -vvv

deploy-ethereum :; forge script script/DeployTransparentProxyFactory.s.sol:DeployEthereum --rpc-url ethereum --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-polygon :; forge script script/DeployTransparentProxyFactory.s.sol:DeployPolygon --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-avalanche :; forge script script/DeployTransparentProxyFactory.s.sol:DeployAvalanche --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-optimism :; forge script script/DeployTransparentProxyFactory.s.sol:DeployOptimism --rpc-url optimism --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-arbitrum :; forge script script/DeployTransparentProxyFactory.s.sol:DeployArbitrum --rpc-url arbitrum --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv

# ---------------------------------------------- BASE SCRIPT CONFIGURATION ---------------------------------------------

BASE_LEDGER = --legacy --mnemonics foo --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER)
BASE_KEY = --private-key ${PRIVATE_KEY}

custom_ethereum := --with-gas-price 25000000000 # 53 gwei
custom_polygon :=  --with-gas-price 170000000000 # 560 gwei
custom_avalanche := --with-gas-price 27000000000 # 27 gwei
custom_metis-testnet := --legacy --verifier-url https://goerli.explorer.metisdevops.link/api/
custom_metis := --verifier-url https://andromeda-explorer.metis.io/api/

# params:
#  1 - path/file_name
#  2 - network name
#  3 - script to call if not the same as network name (optional)
#  to define custom params per network add vars custom_network-name
#  to use ledger, set LEDGER=true to env
#  default to testnet deployment, to run production, set PROD=true to env
define deploy_single_fn
forge script \
 script/$(1).s.sol:$(if $(3),$(3),$(shell UP=$(if $(PROD),$(2),$(2)_testnet); echo $${UP} | perl -nE 'say ucfirst')) \
 --rpc-url $(if $(PROD),$(2),$(2)-testnet) --broadcast --verify --slow -vvvv \
 $(if $(LEDGER),$(BASE_LEDGER),$(BASE_KEY)) \
 $(custom_$(if $(PROD),$(2),$(2)-testnet))

endef

define deploy_fn
 $(foreach network,$(2),$(call deploy_single_fn,$(1),$(network),$(3)))
endef

deploy-create3-factory:
	$(call deploy_fn,DeployCreate3Factory,ethereum avalanche polygon optimism arbitrum binance base metis,DeployCreate3Factory)
