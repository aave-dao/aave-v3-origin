// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Utils
import {AaveV3BatchOrchestration} from 'src/deployments/projects/aave-v3-batched/AaveV3BatchOrchestration.sol';
import {MarketReportUtils} from 'src/deployments/contracts/utilities/MarketReportUtils.sol';
import {WETH9} from 'src/contracts/dependencies/weth/WETH9.sol';
import {Create2Factory, FactoryDeployer} from 'tests/invariants/utils/Create2Factory.sol';

// Contracts
import {Actor} from './utils/Actor.sol';
import {BaseTest} from './base/BaseTest.t.sol';
import {ACLManager} from 'src/contracts/protocol/configuration/ACLManager.sol';

// Test Contracts
import 'src/deployments/interfaces/IMarketReportTypes.sol';
import {TestnetERC20} from 'src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {DefaultMarketInput} from 'src/deployments/inputs/DefaultMarketInput.sol';
import {AaveV3BatchOrchestration} from 'src/deployments/projects/aave-v3-batched/AaveV3BatchOrchestration.sol';
import {AaveV3TestListing} from '../mocks/AaveV3TestListing.sol';
import {MockAggregatorSetPrice} from './utils/mocks/MockAggregatorSetPrice.sol';
import {MockFlashLoanReceiver} from './helpers/FlashLoanReceiver.sol';

// Interfaces
import {IAaveV3ConfigEngine} from '../../src/contracts/extensions/v3-config-engine/AaveV3ConfigEngine.sol';

/// @notice Setup contract for the invariant test Suite, inherited by Tester
contract Setup is BaseTest, DefaultMarketInput {
  using MarketReportUtils for MarketReport;

  /// @notice Number of actors to deploy
  function _setUp() internal {
    // Deploy protocol contracts and protocol actors
    _deployProtocolCore();

    // External helper mappings for actions' sets
    _setupSelectorHelpers();
  }

  /// @notice Deploy protocol core contracts
  function _deployProtocolCore() internal {
    (
      Roles memory roles,
      MarketConfig memory config,
      DeployFlags memory flags,
      MarketReport memory deployedContracts
    ) = _getMarketInput(poolAdmin);

    // Deploy assets
    tokenList.weth = address(new WETH9());

    config.wrappedNativeToken = tokenList.weth;

    // Deploy protocol core
    MarketReport memory r = AaveV3BatchOrchestration.deployAaveV3(
      poolAdmin,
      roles,
      config,
      flags,
      deployedContracts
    );

    AaveV3TestListing testnetListingPayload = new AaveV3TestListing(
      IAaveV3ConfigEngine(r.configEngine),
      roles.poolAdmin,
      tokenList.weth,
      r
    );

    // Set mock assets
    tokenList.wbtc = address(testnetListingPayload.WBTC_ADDRESS());
    tokenList.usdx = address(testnetListingPayload.USDX_ADDRESS());

    ACLManager manager = ACLManager(r.aclManager);
    manager.addPoolAdmin(address(testnetListingPayload));
    testnetListingPayload.execute();

    // Set BaseStorage contracts
    contracts = r.toContractsReport();
    pool = contracts.poolProxy;

    // Set extra variables for ATokens and DebtTokens
    DataTypes.ReserveDataLegacy memory wethReserve = contracts.poolProxy.getReserveData(
      tokenList.weth
    );
    DataTypes.ReserveDataLegacy memory wbtcReserve = contracts.poolProxy.getReserveData(
      tokenList.wbtc
    );
    DataTypes.ReserveDataLegacy memory usdxReserve = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );

    aTokens.push(wethReserve.aTokenAddress);
    aTokens.push(wbtcReserve.aTokenAddress);
    aTokens.push(usdxReserve.aTokenAddress);

    debtTokens.push(wethReserve.variableDebtTokenAddress);
    debtTokens.push(wbtcReserve.variableDebtTokenAddress);
    debtTokens.push(usdxReserve.variableDebtTokenAddress);

    {
      // Set extended price aggregators
      mockPriceAggregatorUSDX = new MockAggregatorSetPrice(1e6);
      mockPriceAggregatorWBTC = new MockAggregatorSetPrice(27000e8);
      mockPriceAggregatorWETH = new MockAggregatorSetPrice(1800e8);

      priceAggregators = [
        address(mockPriceAggregatorUSDX),
        address(mockPriceAggregatorWBTC),
        address(mockPriceAggregatorWETH)
      ];

      address[] memory assets = new address[](3);
      assets[0] = tokenList.usdx;
      assets[1] = tokenList.wbtc;
      assets[2] = tokenList.weth;

      address[] memory sources = new address[](3);
      sources[0] = address(mockPriceAggregatorUSDX);
      sources[1] = address(mockPriceAggregatorWBTC);
      sources[2] = address(mockPriceAggregatorWETH);

      contracts.aaveOracle.setAssetSources(assets, sources);
    }

    weth = WETH9(payable(tokenList.weth));
    wbtc = TestnetERC20(tokenList.wbtc);
    usdx = TestnetERC20(tokenList.usdx);

    baseAssets = [tokenList.weth, tokenList.wbtc, tokenList.usdx];

    // Set protocol tokens
    protocolTokens[tokenList.weth] = ProtocolTokens(
      wethReserve.aTokenAddress,
      wethReserve.variableDebtTokenAddress,
      wethReserve.id
    );
    protocolTokens[tokenList.wbtc] = ProtocolTokens(
      wbtcReserve.aTokenAddress,
      wbtcReserve.variableDebtTokenAddress,
      wbtcReserve.id
    );
    protocolTokens[tokenList.usdx] = ProtocolTokens(
      usdxReserve.aTokenAddress,
      usdxReserve.variableDebtTokenAddress,
      usdxReserve.id
    );

    flashLoanReceiver = address(new MockFlashLoanReceiver());
  }

  /// @notice Deploy protocol actors and initialize their balances
  function _setUpActors() internal {
    // Initialize the three actors of the fuzzers
    address[] memory addresses = new address[](3);
    addresses[0] = USER1;
    addresses[1] = USER2;
    addresses[2] = USER3;

    // Initialize the tokens array
    address[] memory tokens = new address[](3);
    tokens[0] = tokenList.usdx;
    tokens[1] = tokenList.wbtc;
    tokens[2] = tokenList.weth;

    address[] memory contracts_ = new address[](1);
    contracts_[0] = address(contracts.poolProxy);

    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      // Deploy actor proxies and approve system contracts_
      address _actor = _setUpActor(addresses[i], tokens, contracts_);

      // Mint initial balances to actors
      for (uint256 j = 0; j < tokens.length; j++) {
        if (tokens[j] == address(tokenList.weth)) {
          weth.deposit{value: INITIAL_BALANCE}();
          weth.transfer(_actor, INITIAL_BALANCE);
        } else {
          TestnetERC20 _token = TestnetERC20(tokens[j]);
          _token.mint(_actor, INITIAL_BALANCE);
        }
      }
      actorAddresses.push(_actor);
    }

    // Set umbrella
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), UMBRELLA);
  }

  /// @notice Deploy an actor proxy contract for a user address
  /// @param userAddress Address of the user
  /// @param tokens Array of token addresses
  /// @param contracts_ Array of contract addresses to aprove tokens to
  /// @return actorAddress Address of the deployed actor
  function _setUpActor(
    address userAddress,
    address[] memory tokens,
    address[] memory contracts_
  ) internal returns (address) {
    return address(actors[userAddress] = new Actor(tokens, contracts_));
  }

  function _etchCreate2Factory() internal virtual {
    FactoryDeployer deployer = new FactoryDeployer();

    // Etch the create2 factory
    vm.etch(0xE1CB04A0fA36DdD16a06ea828007E35e1a3cBC37, address(deployer).code);

    vm.setNonce(0xE1CB04A0fA36DdD16a06ea828007E35e1a3cBC37, 0);

    FactoryDeployer(0xE1CB04A0fA36DdD16a06ea828007E35e1a3cBC37).deployFactory();
  }

  function _setupSelectorHelpers() internal {
    /// @dev HF TRANSITION ACTIONS
    // nonDecreasingHfActions
    for (uint256 i; i < nonDecreasingHfActions.length; i++) {
      isNonDecreasingHfAction[nonDecreasingHfActions[i]] = true;
    }
    // nonIncreasingHfActions
    for (uint256 i; i < nonIncreasingHfActions.length; i++) {
      isNonIncreasingHfAction[nonIncreasingHfActions[i]] = true;
    }

    /// @dev UNSAFE HF ACTIONS
    // hfUnsafeAfterActions
    for (uint256 i; i < hfUnsafeAfterActions.length; i++) {
      isHfUnsafeAfterAction[hfUnsafeAfterActions[i]] = true;
    }
    // hfUnsafeBeforeActions
    for (uint256 i; i < hfUnsafeBeforeActions.length; i++) {
      isHfUnsafeBeforeAction[hfUnsafeBeforeActions[i]] = true;
    }
  }
}
