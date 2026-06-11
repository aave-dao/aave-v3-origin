// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {DeployAaveV3MarketBatchedBase} from './misc/DeployAaveV3MarketBatchedBase.sol';

import {MonadMarketInput} from '../src/deployments/inputs/MonadMarketInput.sol';

/**
 * Aave V3 — Monad mainnet (chainId 143) deployment.
 *
 * Prereqs:
 *  - fill OWNER / POOL_ADMIN / EMERGENCY_ADMIN in src/deployments/inputs/MonadMarketInput.sol
 *  - set RPC_MONAD in .env
 *  - import the deployer into a Foundry keystore account once:
 *      cast wallet import monad-deployer --interactive   # paste the private key, set a password
 *    then export its address:  export DEPLOYER=0xYourDeployerAddress
 *
 * Run from the repo root (signs with the encrypted keystore account; prompts for its password):
 *
 *   # 1) precompile libraries batch 1 (writes FOUNDRY_LIBRARIES into .env via FFI)
 *   forge script scripts/misc/LibraryPreCompileOne.sol --rpc-url $RPC_MONAD \
 *     --account monad-deployer --sender $DEPLOYER --slow --broadcast --verify
 *
 *   # 2) precompile libraries batch 2 (appends the remaining libraries to FOUNDRY_LIBRARIES)
 *   forge script scripts/misc/LibraryPreCompileTwo.sol --rpc-url $RPC_MONAD \
 *     --account monad-deployer --sender $DEPLOYER --slow --broadcast --verify
 *
 *   # 3) deploy the market
 *   forge script scripts/DeployAaveV3MonadMarket.sol:Monad --rpc-url $RPC_MONAD \
 *     --account monad-deployer --sender $DEPLOYER --slow --broadcast --verify
 *
 * Verification (optional, append to step 3): --verify --verifier etherscan \
 *   --verifier-url https://api.monadscan.com/api --etherscan-api-key $ETHERSCAN_API_KEY
 *   (or --chain 143 if Etherscan V2 multichain covers Monad).
 */
contract Monad is DeployAaveV3MarketBatchedBase, MonadMarketInput {}
