// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script, console2} from 'forge-std/Script.sol';
import {MarketConfig, UBCMarketConfig, NetworkAddresses} from './config/MarketConfig.sol';

// Protocol imports
import {JUBCToken} from 'custom/jubc/JUBCToken.sol';
import {JUBCDiscountRateStrategy} from 'custom/jubc/JUBCDiscountRateStrategy.sol';
import {DataStreamAggregatorAdapter} from 'custom/oracles/DataStreamAggregatorAdapter.sol';
import {JpyUbiAMOMinter} from 'custom/amo/JpyUbiAMOMinter.sol';
import {JpyUbiConvexAMO} from 'custom/amo/JpyUbiConvexAMO.sol';

/**
 * @title DeployUBCMarket
 * @notice Main deployment script for UBC Market
 * @dev Run with: forge script scripts/custom/DeployUBCMarket.s.sol:DeployUBCMarket --rpc-url $RPC_URL --broadcast
 */
contract DeployUBCMarket is Script {
  // Deployed addresses
  JUBCToken public jUBCToken;
  DataStreamAggregatorAdapter public jpyUsdOracle;
  JUBCDiscountRateStrategy public discountRateStrategy;
  JpyUbiAMOMinter public amoMinter;

  // Config
  address public deployer;
  address public admin;
  address public treasury;

  // Chainlink Data Streams
  address public verifierProxy;
  bytes32 public jpyUsdFeedId;

  function setUp() public {
    deployer = vm.envOr('DEPLOYER', msg.sender);
    admin = vm.envOr('ADMIN', deployer);
    treasury = vm.envOr('TREASURY', deployer);

    // Default verifier proxy (Mainnet)
    verifierProxy = vm.envOr('VERIFIER_PROXY', address(0x2ff010DEbC1297f19579B4246cad07bd24F2488A));
    jpyUsdFeedId = vm.envOr('JPY_USD_FEED_ID', keccak256('JPY/USD'));
  }

  function run() external {
    vm.startBroadcast(deployer);

    // Step 1: Deploy jUBC Token
    _deployJUBCToken();

    // Step 2: Deploy Oracle
    _deployOracle();

    // Step 3: Deploy Discount Rate Strategy
    _deployDiscountRateStrategy();

    // Step 4: Deploy AMO Minter
    _deployAMOMinter();

    // Step 5: Configure roles
    _configureRoles();

    vm.stopBroadcast();

    // Log deployed addresses
    _logDeployedAddresses();
  }

  function _deployJUBCToken() internal {
    console2.log('Deploying JUBCToken...');
    jUBCToken = new JUBCToken(admin);
    console2.log('JUBCToken deployed at:', address(jUBCToken));
  }

  function _deployOracle() internal {
    console2.log('Deploying DataStreamAggregatorAdapter...');
    jpyUsdOracle = new DataStreamAggregatorAdapter(verifierProxy, jpyUsdFeedId, 8, 'JPY / USD');
    console2.log('DataStreamAggregatorAdapter deployed at:', address(jpyUsdOracle));
  }

  function _deployDiscountRateStrategy() internal {
    console2.log('Deploying JUBCDiscountRateStrategy...');
    // Uses GHO defaults: 30% discount, 100 AIEN discounted per discount token
    discountRateStrategy = new JUBCDiscountRateStrategy();
    console2.log('JUBCDiscountRateStrategy deployed at:', address(discountRateStrategy));
  }

  function _deployAMOMinter() internal {
    console2.log('Deploying JpyUbiAMOMinter...');
    uint256 globalMintCap = 100_000_000e18; // 100M jUBC
    amoMinter = new JpyUbiAMOMinter(address(jUBCToken), globalMintCap);
    console2.log('JpyUbiAMOMinter deployed at:', address(amoMinter));
  }

  function _configureRoles() internal {
    console2.log('Configuring roles...');

    // Grant facilitator manager role to admin
    bytes32 FACILITATOR_MANAGER_ROLE = keccak256('FACILITATOR_MANAGER_ROLE');
    bytes32 BUCKET_MANAGER_ROLE = keccak256('BUCKET_MANAGER_ROLE');

    jUBCToken.grantRole(FACILITATOR_MANAGER_ROLE, admin);
    jUBCToken.grantRole(BUCKET_MANAGER_ROLE, admin);

    // Authorize keeper for oracle
    jpyUsdOracle.setKeeperAuthorization(admin, true);

    console2.log('Roles configured');
  }

  function _logDeployedAddresses() internal view {
    console2.log('');
    console2.log('========================================');
    console2.log('DEPLOYED ADDRESSES');
    console2.log('========================================');
    console2.log('JUBCToken:', address(jUBCToken));
    console2.log('JpyUsdOracle:', address(jpyUsdOracle));
    console2.log('DiscountRateStrategy:', address(discountRateStrategy));
    console2.log('AMOMinter:', address(amoMinter));
    console2.log('========================================');
    console2.log('');
  }
}

/**
 * @title DeployTokensOnly
 * @notice Deploys only the token contracts for testing
 */
contract DeployTokensOnly is Script {
  function run() external {
    address deployer = vm.envOr('DEPLOYER', msg.sender);
    address admin = vm.envOr('ADMIN', deployer);

    vm.startBroadcast(deployer);

    // Deploy jUBC token
    JUBCToken jUBCToken = new JUBCToken(admin);
    console2.log('JUBCToken deployed at:', address(jUBCToken));

    // Grant roles
    bytes32 FACILITATOR_MANAGER_ROLE = keccak256('FACILITATOR_MANAGER_ROLE');
    bytes32 BUCKET_MANAGER_ROLE = keccak256('BUCKET_MANAGER_ROLE');
    jUBCToken.grantRole(FACILITATOR_MANAGER_ROLE, admin);
    jUBCToken.grantRole(BUCKET_MANAGER_ROLE, admin);

    vm.stopBroadcast();
  }
}

/**
 * @title DeployOracle
 * @notice Deploys oracle contracts
 */
contract DeployOracle is Script {
  function run() external {
    address deployer = vm.envOr('DEPLOYER', msg.sender);
    address verifierProxy = vm.envOr('VERIFIER_PROXY', address(0x2ff010DEbC1297f19579B4246cad07bd24F2488A));
    bytes32 feedId = vm.envOr('FEED_ID', keccak256('JPY/USD'));

    vm.startBroadcast(deployer);

    DataStreamAggregatorAdapter oracle = new DataStreamAggregatorAdapter(verifierProxy, feedId, 8, 'JPY / USD');

    console2.log('DataStreamAggregatorAdapter deployed at:', address(oracle));

    // Authorize deployer as keeper
    oracle.setKeeperAuthorization(deployer, true);

    vm.stopBroadcast();
  }
}

/**
 * @title ConfigureFacilitator
 * @notice Configures a facilitator for jUBC token
 */
contract ConfigureFacilitator is Script {
  function run() external {
    address deployer = vm.envOr('DEPLOYER', msg.sender);
    address jUBCAddress = vm.envAddress('JUBC_ADDRESS');
    address facilitator = vm.envAddress('FACILITATOR');
    string memory label = vm.envOr('LABEL', string('Aave V3 Pool'));
    uint128 capacity = uint128(vm.envOr('CAPACITY', uint256(100_000_000e18)));

    vm.startBroadcast(deployer);

    JUBCToken jUBC = JUBCToken(jUBCAddress);
    jUBC.addFacilitator(facilitator, label, capacity);

    console2.log('Facilitator added:');
    console2.log('  Address:', facilitator);
    console2.log('  Label:', label);
    console2.log('  Capacity:', capacity);

    vm.stopBroadcast();
  }
}
