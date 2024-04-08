// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AToken} from 'aave-v3-core/contracts/protocol/tokenization/AToken.sol';
import {VariableDebtToken} from 'aave-v3-core/contracts/protocol/tokenization/VariableDebtToken.sol';
import {StableDebtToken} from 'aave-v3-core/contracts/protocol/tokenization/StableDebtToken.sol';
import {Errors} from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {ConfiguratorInputTypes, IPool, IPoolAddressesProvider} from 'aave-v3-core/contracts/protocol/pool/PoolConfigurator.sol';
import {MockATokenRepayment} from 'aave-v3-core/contracts/mocks/tokens/MockATokenRepayment.sol';
import {MockVariableDebtToken, MockStableDebtToken} from 'aave-v3-core/contracts/mocks/tokens/MockDebtTokens.sol';
import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveLogic} from 'aave-v3-core/contracts/protocol/libraries/logic/ReserveLogic.sol';

import {SlotParser} from '../utils/SlotParser.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract PoolConfiguratorUpgradeabilityTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;

  DataTypes.ReserveData internal reserveData;
  DataTypes.ReserveData internal updatedReserveData;

  event ReserveInterestRateStrategyChanged(
    address indexed asset,
    address oldStrategy,
    address newStrategy
  );

  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  function setUp() public {
    initTestEnvironment();
  }

  function test_getConfiguratorLogic() public {
    assertNotEq(contracts.poolConfiguratorProxy.getConfiguratorLogic(), address(0));
  }

  function test_setReserveInterestRateStrategyAddress() public {
    address currentInterestRateStrategy = contracts
      .protocolDataProvider
      .getInterestRateStrategyAddress(tokenList.usdx);
    address updatedInterestsRateStrategy = _deployInterestRateStrategy();

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit ReserveInterestRateStrategyChanged(
      tokenList.usdx,
      currentInterestRateStrategy,
      updatedInterestsRateStrategy
    );

    // Perform change
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveInterestRateStrategyAddress(
      tokenList.usdx,
      updatedInterestsRateStrategy,
      _getDefaultInterestRatesStrategyData()
    );

    address newInterestRateStrategy = contracts.protocolDataProvider.getInterestRateStrategyAddress(
      tokenList.usdx
    );

    assertEq(newInterestRateStrategy, updatedInterestsRateStrategy);
  }

  function test_interestRateStrategy_update() public {
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);

    uint256 amount = 100_000e6;
    uint256 borrowAmount = 30_000e6;

    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);

    vm.stopPrank();

    reserveData = contracts.poolProxy.getReserveDataExtended(tokenList.usdx);
    DataTypes.ReserveCache memory cache = reserveData.cache();

    assertEq(cache.currVariableBorrowIndex, 1e27);
    assertEq(cache.currVariableBorrowRate, 13333333333333333333333333);

    vm.warp(block.timestamp + 365 days);

    // check that index is not changed after 1 year
    updatedReserveData = contracts.poolProxy.getReserveDataExtended(tokenList.usdx);
    DataTypes.ReserveCache memory cacheAfterYear = updatedReserveData.cache();

    assertEq(cacheAfterYear.currVariableBorrowIndex, 1e27);

    address updatedInterestsRateStrategy = _deployInterestRateStrategy();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveInterestRateStrategyAddress(
      tokenList.usdx,
      updatedInterestsRateStrategy,
      _getDefaultInterestRatesStrategyData()
    );

    // index and borrow rate have changed after IRS update
    updatedReserveData = contracts.poolProxy.getReserveDataExtended(tokenList.usdx);
    DataTypes.ReserveCache memory updatedCache = updatedReserveData.cache();

    assertGt(updatedCache.currVariableBorrowIndex, 1e27);
    assertEq(updatedCache.currVariableBorrowRate, 107585394738663515131637198);
  }

  function test_updateAToken() public {
    ConfiguratorInputTypes.UpdateATokenInput memory input = ConfiguratorInputTypes
      .UpdateATokenInput({
        asset: tokenList.usdx,
        treasury: report.treasury,
        incentivesController: address(2),
        name: 'New USDX Test AToken',
        symbol: 'aTestUSDX',
        implementation: address(new MockATokenRepayment(IPool(report.poolProxy))),
        params: bytes('')
      });
    (address aTokenProxy, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );

    address previousImplementation = SlotParser.loadAddressFromSlot(
      aTokenProxy,
      bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );

    // Perform upgrade
    vm.startPrank(poolAdmin);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit ATokenUpgraded(tokenList.usdx, aTokenProxy, input.implementation);

    contracts.poolConfiguratorProxy.updateAToken(input);
    vm.stopPrank();

    address upgradedImplementation = SlotParser.loadAddressFromSlot(
      aTokenProxy,
      bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );

    assertTrue(upgradedImplementation != previousImplementation);
    assertEq(upgradedImplementation, input.implementation);
    assertEq(AToken(aTokenProxy).name(), input.name);
    assertEq(AToken(aTokenProxy).symbol(), input.symbol);
    assertEq(address(AToken(aTokenProxy).getIncentivesController()), input.incentivesController);
    assertEq(AToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(), input.treasury);
  }

  function test_updateVariableDebtToken() public {
    (, , address variableDebtProxy) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );
    ConfiguratorInputTypes.UpdateDebtTokenInput memory input = ConfiguratorInputTypes
      .UpdateDebtTokenInput({
        asset: tokenList.usdx,
        incentivesController: report.rewardsControllerProxy,
        name: 'New Variable Debt Test USDX',
        symbol: 'newTestVarDebtUSDX',
        implementation: address(new MockVariableDebtToken(IPool(report.poolProxy))),
        params: bytes('')
      });

    address previousImplementation = SlotParser.loadAddressFromSlot(
      variableDebtProxy,
      bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );

    // Perform upgrade
    vm.startPrank(poolAdmin);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit VariableDebtTokenUpgraded(tokenList.usdx, variableDebtProxy, input.implementation);

    contracts.poolConfiguratorProxy.updateVariableDebtToken(input);
    vm.stopPrank();

    address upgradedImplementation = SlotParser.loadAddressFromSlot(
      variableDebtProxy,
      bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );

    assertTrue(upgradedImplementation != previousImplementation);
    assertEq(upgradedImplementation, input.implementation);
    assertEq(VariableDebtToken(variableDebtProxy).name(), input.name);
    assertEq(VariableDebtToken(variableDebtProxy).symbol(), input.symbol);
    assertEq(
      address(VariableDebtToken(variableDebtProxy).getIncentivesController()),
      input.incentivesController
    );
  }

  function test_updateStableDebtToken() public {
    (, address stableDebtToken, ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );
    ConfiguratorInputTypes.UpdateDebtTokenInput memory input = ConfiguratorInputTypes
      .UpdateDebtTokenInput({
        asset: tokenList.usdx,
        incentivesController: report.rewardsControllerProxy,
        name: 'New Stable Debt Test USDX',
        symbol: 'newTestStaDebtUSDX',
        implementation: address(new MockStableDebtToken(IPool(report.poolProxy))),
        params: bytes('')
      });

    address previousImplementation = SlotParser.loadAddressFromSlot(
      stableDebtToken,
      bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );

    vm.startPrank(poolAdmin);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit StableDebtTokenUpgraded(tokenList.usdx, stableDebtToken, input.implementation);

    // Perform upgrade
    contracts.poolConfiguratorProxy.updateStableDebtToken(input);
    vm.stopPrank();

    address upgradedImplementation = SlotParser.loadAddressFromSlot(
      stableDebtToken,
      bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );

    assertTrue(upgradedImplementation != previousImplementation);
    assertEq(upgradedImplementation, input.implementation);
    assertEq(StableDebtToken(stableDebtToken).name(), input.name);
    assertEq(StableDebtToken(stableDebtToken).symbol(), input.symbol);
    assertEq(
      address(StableDebtToken(stableDebtToken).getIncentivesController()),
      input.incentivesController
    );
  }
}
