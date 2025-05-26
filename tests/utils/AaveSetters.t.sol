// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {TestnetProcedures} from './TestnetProcedures.sol';
import {AaveSetters} from './AaveSetters.sol';
import {WadRayMath} from '../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {IAToken, IERC20} from '../../src/contracts/interfaces/IAToken.sol';

contract AaveSettersTest is TestnetProcedures {
  address internal user = user;

  address internal asset;
  address internal aToken;
  address internal vToken;

  function setUp() external {
    initTestEnvironment();

    asset = tokenList.weth;
    aToken = contracts.poolProxy.getReserveAToken(asset);
    vToken = contracts.poolProxy.getReserveVariableDebtToken(asset);

    // make supply rate not zero
    _supplyAndEnableAsCollateral({user: user, amount: 100 ether, asset: asset});

    // make borrow rate not zero
    vm.prank(user);
    contracts.poolProxy.borrow({
      asset: asset,
      amount: 10 ether,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: user
    });
  }

  function test_setLiquidityIndex() external {
    DataTypes.ReserveDataLegacy memory oldReserveData = contracts.poolProxy.getReserveData(asset);

    uint256 newLiquidityIndex = oldReserveData.liquidityIndex * 2;
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, newLiquidityIndex);
    assertEq(contracts.poolProxy.getReserveData(asset).liquidityIndex, newLiquidityIndex);
    assertEq(
      contracts.poolProxy.getReserveData(asset).currentLiquidityRate,
      oldReserveData.currentLiquidityRate
    );
  }

  function test_setVariableBorrowIndex() external {
    DataTypes.ReserveDataLegacy memory oldReserveData = contracts.poolProxy.getReserveData(asset);

    uint256 newVariableBorrowIndex = oldReserveData.variableBorrowIndex * 2;
    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, newVariableBorrowIndex);
    assertEq(contracts.poolProxy.getReserveData(asset).variableBorrowIndex, newVariableBorrowIndex);
    assertEq(
      contracts.poolProxy.getReserveData(asset).currentVariableBorrowRate,
      oldReserveData.currentVariableBorrowRate
    );
  }

  function test_setLastUpdateTimestamp() external {
    uint256 oldReserveDeficit = contracts.poolProxy.getReserveDeficit(asset);
    uint256 oldLiquidationGracePeriod = contracts.poolProxy.getLiquidationGracePeriod(asset);
    DataTypes.ReserveDataLegacy memory oldReserveData = contracts.poolProxy.getReserveData(asset);

    uint40 newTimestamp = oldReserveData.lastUpdateTimestamp + 1 days;
    AaveSetters.setLastUpdateTimestamp(report.poolProxy, asset, newTimestamp);

    DataTypes.ReserveDataLegacy memory newReserveData = contracts.poolProxy.getReserveData(asset);

    assertEq(contracts.poolProxy.getReserveDeficit(asset), oldReserveDeficit);
    assertEq(contracts.poolProxy.getLiquidationGracePeriod(asset), oldLiquidationGracePeriod);
    assertEq(newReserveData.id, oldReserveData.id);
    assertEq(newReserveData.lastUpdateTimestamp, newTimestamp);
  }

  function test_setATokenBalance() external {
    AaveSetters.setATokenBalance(aToken, user, 1000, 1e27);
    assertEq(IAToken(aToken).scaledBalanceOf(user), 1000);
    assertEq(IAToken(aToken).balanceOf(user), 1000);

    AaveSetters.setLiquidityIndex(address(contracts.poolProxy), asset, 2e27);
    assertEq(IAToken(aToken).balanceOf(user), 2000);
  }

  function test_setATokenTotalSupply() external {
    AaveSetters.setATokenTotalSupply(aToken, 1000);
    assertEq(IAToken(aToken).scaledTotalSupply(), 1000);
    assertEq(IAToken(aToken).totalSupply(), 1000);

    AaveSetters.setLiquidityIndex(address(contracts.poolProxy), asset, 2e27);
    assertEq(IAToken(aToken).totalSupply(), 2000);
  }

  function test_setVTokenBalance() external {
    AaveSetters.setVariableDebtTokenBalance(vToken, user, 1000, 1e27);
    assertEq(IAToken(vToken).scaledBalanceOf(user), 1000);
    assertEq(IAToken(vToken).balanceOf(user), 1000);

    AaveSetters.setVariableBorrowIndex(address(contracts.poolProxy), asset, 2e27);
    assertEq(IAToken(vToken).balanceOf(user), 2000);
  }

  function test_setVTokenTotalSupply() external {
    AaveSetters.setVariableDebtTokenTotalSupply(vToken, 1000);
    assertEq(IAToken(vToken).scaledTotalSupply(), 1000);
    assertEq(IAToken(vToken).totalSupply(), 1000);

    AaveSetters.setVariableBorrowIndex(address(contracts.poolProxy), asset, 2e27);
    assertEq(IAToken(vToken).totalSupply(), 2000);
  }
}
