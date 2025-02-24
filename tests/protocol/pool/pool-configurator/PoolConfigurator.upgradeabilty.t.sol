// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AToken} from '../../../../src/contracts/protocol/tokenization/AToken.sol';
import {VariableDebtToken} from '../../../../src/contracts/protocol/tokenization/VariableDebtToken.sol';
import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ConfiguratorInputTypes, IPool, IPoolAddressesProvider} from '../../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {MockATokenRepayment} from '../../../../src/contracts/mocks/tokens/MockATokenRepayment.sol';
import {MockVariableDebtToken} from '../../../../src/contracts/mocks/tokens/MockDebtTokens.sol';
import {DataTypes} from '../../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveLogic} from '../../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';

import {SlotParser} from '../../../utils/SlotParser.sol';
import {TestnetProcedures} from '../../../utils/TestnetProcedures.sol';

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

  event ReserveInterestRateDataChanged(address indexed asset, address indexed strategy, bytes data);

  event ATokenUpgraded(
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

  function test_getConfiguratorLogic() public view {
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

  function test_setReserveInterestRateData() public {
    address currentInterestRateStrategy = contracts
      .protocolDataProvider
      .getInterestRateStrategyAddress(tokenList.usdx);

    bytes memory newInterestRateData = _getDefaultInterestRatesStrategyData();

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit ReserveInterestRateDataChanged(
      tokenList.usdx,
      currentInterestRateStrategy,
      newInterestRateData
    );

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveInterestRateData(
      tokenList.usdx,
      _getDefaultInterestRatesStrategyData()
    );

    address newInterestRateStrategy = contracts.protocolDataProvider.getInterestRateStrategyAddress(
      tokenList.usdx
    );
    assertEq(currentInterestRateStrategy, newInterestRateStrategy);
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

    reserveData = _getFullReserveData(tokenList.usdx);
    DataTypes.ReserveCache memory cache = reserveData.cache();

    assertEq(cache.currVariableBorrowIndex, 1e27);
    assertEq(cache.currVariableBorrowRate, 13333333333333333333333333);

    vm.warp(block.timestamp + 365 days);

    // check that index is not changed after 1 year
    updatedReserveData = _getFullReserveData(tokenList.usdx);
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
    updatedReserveData = _getFullReserveData(tokenList.usdx);
    DataTypes.ReserveCache memory updatedCache = updatedReserveData.cache();

    assertGt(updatedCache.currVariableBorrowIndex, 1e27);
    assertEq(updatedCache.currVariableBorrowRate, 107585394738663515131637198);
  }

  // TODO: deduplicate, reuse in vTokenUpdate too
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

  function _getFullReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
    DataTypes.ReserveDataLegacy memory reserveDataLegacy = contracts.poolProxy.getReserveData(
      asset
    );
    DataTypes.ReserveData memory tempReserveData;
    tempReserveData.configuration = reserveDataLegacy.configuration;
    tempReserveData.liquidityIndex = reserveDataLegacy.liquidityIndex;
    tempReserveData.currentLiquidityRate = reserveDataLegacy.currentLiquidityRate;
    tempReserveData.variableBorrowIndex = reserveDataLegacy.variableBorrowIndex;
    tempReserveData.currentVariableBorrowRate = reserveDataLegacy.currentVariableBorrowRate;
    tempReserveData.lastUpdateTimestamp = reserveDataLegacy.lastUpdateTimestamp;
    tempReserveData.id = reserveDataLegacy.id;
    tempReserveData.aTokenAddress = reserveDataLegacy.aTokenAddress;
    tempReserveData.variableDebtTokenAddress = reserveDataLegacy.variableDebtTokenAddress;
    tempReserveData.interestRateStrategyAddress = reserveDataLegacy.interestRateStrategyAddress;
    tempReserveData.accruedToTreasury = reserveDataLegacy.accruedToTreasury;
    tempReserveData.unbacked = reserveDataLegacy.unbacked;
    tempReserveData.isolationModeTotalDebt = reserveDataLegacy.isolationModeTotalDebt;
    tempReserveData.virtualUnderlyingBalance = uint128(
      contracts.poolProxy.getVirtualUnderlyingBalance(asset)
    );
    tempReserveData.deficit = uint128(contracts.poolProxy.getReserveDeficit(asset));
    return tempReserveData;
  }
}
