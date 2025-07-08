// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AToken} from '../../../../src/contracts/protocol/tokenization/AToken.sol';
import {VariableDebtToken} from '../../../../src/contracts/protocol/tokenization/VariableDebtToken.sol';
import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ConfiguratorInputTypes, IPool, IPoolAddressesProvider, IPoolConfigurator} from '../../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {MockAToken} from '../../../../src/contracts/mocks/tokens/MockAToken.sol';
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

  function setUp() public {
    initTestEnvironment();
  }

  function test_getConfiguratorLogic() public view {
    assertNotEq(contracts.poolConfiguratorProxy.getConfiguratorLogic(), address(0));
  }

  function test_setReserveInterestRateData() public {
    address currentInterestRateStrategy = contracts
      .protocolDataProvider
      .getInterestRateStrategyAddress(tokenList.usdx);
    assertEq(currentInterestRateStrategy, report.defaultInterestRateStrategy);

    bytes memory newInterestRateData = _getDefaultInterestRatesStrategyData();

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveInterestRateDataChanged(
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
    address newInterestRateStrategyFromGetReserveData = contracts
      .poolProxy
      .getReserveData(tokenList.usdx)
      .interestRateStrategyAddress;

    assertEq(currentInterestRateStrategy, newInterestRateStrategy);
    assertEq(currentInterestRateStrategy, newInterestRateStrategyFromGetReserveData);
  }

  // TODO: deduplicate, reuse in vTokenUpdate too
  function test_updateAToken() public {
    ConfiguratorInputTypes.UpdateATokenInput memory input = ConfiguratorInputTypes
      .UpdateATokenInput({
        asset: tokenList.usdx,
        name: 'New USDX Test AToken',
        symbol: 'aTestUSDX',
        implementation: address(
          new MockAToken(IPool(report.poolProxy), report.rewardsControllerProxy, report.treasury)
        ),
        params: bytes('')
      });
    address aTokenProxy = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    address previousImplementation = SlotParser.loadAddressFromSlot(
      aTokenProxy,
      bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );

    // Perform upgrade
    vm.startPrank(poolAdmin);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ATokenUpgraded(tokenList.usdx, aTokenProxy, input.implementation);

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
    assertEq(address(AToken(aTokenProxy).getIncentivesController()), report.rewardsControllerProxy);
    assertEq(AToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(), report.treasury);
  }

  function test_updateVariableDebtToken() public {
    address variableDebtProxy = contracts.poolProxy.getReserveVariableDebtToken(tokenList.usdx);
    ConfiguratorInputTypes.UpdateDebtTokenInput memory input = ConfiguratorInputTypes
      .UpdateDebtTokenInput({
        asset: tokenList.usdx,
        name: 'New Variable Debt Test USDX',
        symbol: 'newTestVarDebtUSDX',
        implementation: address(
          new MockVariableDebtToken(IPool(report.poolProxy), report.rewardsControllerProxy)
        ),
        params: bytes('')
      });

    address previousImplementation = SlotParser.loadAddressFromSlot(
      variableDebtProxy,
      bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );

    // Perform upgrade
    vm.startPrank(poolAdmin);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.VariableDebtTokenUpgraded(
      tokenList.usdx,
      variableDebtProxy,
      input.implementation
    );

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
      report.rewardsControllerProxy
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
    tempReserveData.__deprecatedInterestRateStrategyAddress = reserveDataLegacy
      .interestRateStrategyAddress;
    tempReserveData.accruedToTreasury = reserveDataLegacy.accruedToTreasury;
    tempReserveData.isolationModeTotalDebt = reserveDataLegacy.isolationModeTotalDebt;
    tempReserveData.virtualUnderlyingBalance = uint128(
      contracts.poolProxy.getVirtualUnderlyingBalance(asset)
    );
    tempReserveData.deficit = uint128(contracts.poolProxy.getReserveDeficit(asset));
    return tempReserveData;
  }
}
