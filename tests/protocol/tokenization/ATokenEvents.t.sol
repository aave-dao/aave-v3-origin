// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken, IERC20, IScaledBalanceToken} from '../../../src/contracts/interfaces/IAToken.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {ReserveLogic} from '../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {MathUtils} from '../../../src/contracts/protocol/libraries/math/MathUtils.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';

contract ATokenEventsTests is TestnetProcedures {
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveDataLegacy;

  IAToken public aToken;

  function setUp() public {
    initTestEnvironment();

    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    aToken = IAToken(aUSDX);
  }

  function _expectATokenSupplyEvents(
    address underlyingToken,
    address aTokenAddress,
    address user,
    address onBehalfOf,
    uint256 amount,
    bool checkInterestsNonZero
  ) internal {
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      underlyingToken
    );

    uint256 oldIndex;
    uint256 newIndex;
    {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
        reserveData.currentLiquidityRate,
        reserveData.lastUpdateTimestamp
      );

      oldIndex = IAToken(aTokenAddress).getPreviousIndex(onBehalfOf);
      newIndex = cumulatedLiquidityInterest.rayMul(reserveData.liquidityIndex);
    }

    uint256 mintAmount;
    uint256 balanceIncrease;
    {
      uint256 scaledBalance = IAToken(aTokenAddress).scaledBalanceOf(onBehalfOf);
      uint256 scaledMintAmount = amount.rayDivFloor(newIndex);
      uint256 nextBalance = (scaledBalance + scaledMintAmount).rayMulFloor(newIndex);
      uint256 previousBalance = scaledBalance.rayMulFloor(oldIndex);
      balanceIncrease = scaledBalance.rayMulFloor(newIndex) - previousBalance;
      mintAmount = nextBalance - previousBalance;
    }

    if (checkInterestsNonZero) {
      assertTrue(
        balanceIncrease > 0,
        'Intention failed: balanceIncrease should be greater than zero'
      );
    }

    vm.expectEmit(address(underlyingToken));
    emit IERC20.Transfer(user, aTokenAddress, amount);
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(address(0), onBehalfOf, mintAmount);
    vm.expectEmit(address(aToken));
    emit IScaledBalanceToken.Mint(user, onBehalfOf, mintAmount, balanceIncrease, newIndex);
  }

  function _expectATokenWithdrawEvents(
    address underlyingToken,
    address aTokenAddress,
    address user,
    address target,
    uint256 amount,
    bool checkAmountLessThanInterests,
    bool checkInterestsNonZero
  ) internal {
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      underlyingToken
    );

    uint256 oldIndex;
    uint256 newIndex;
    {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
        reserveData.currentLiquidityRate,
        reserveData.lastUpdateTimestamp
      );

      oldIndex = IAToken(aTokenAddress).getPreviousIndex(user);
      newIndex = cumulatedLiquidityInterest.rayMul(reserveData.liquidityIndex);
    }

    int256 deltaAmount;
    uint256 balanceIncrease;
    {
      uint256 scaledBalance = IAToken(aTokenAddress).scaledBalanceOf(user);
      uint256 scaledBurnAmount = amount.rayDivCeil(newIndex);
      uint256 nextBalance = (scaledBalance - scaledBurnAmount).rayMulFloor(newIndex);
      uint256 previousBalance = scaledBalance.rayMulFloor(oldIndex);
      balanceIncrease = scaledBalance.rayMulFloor(newIndex) - previousBalance;
      deltaAmount = int256(nextBalance) - int256(previousBalance);
    }

    // Ensure test intention via bool to determine if withdrawal amount should be less than interests
    if (checkAmountLessThanInterests) {
      assertTrue(
        balanceIncrease > amount,
        'Intention failed: balanceIncrease should be greater than amount'
      );
    } else {
      assertTrue(
        amount > balanceIncrease,
        'Intention failed: amount should be greater than balanceIncrease'
      );
    }
    if (checkInterestsNonZero) {
      assertTrue(
        balanceIncrease > 0,
        'Intention failed: balanceIncrease should be greater than zero'
      );
    }
    if (deltaAmount > 0) {
      vm.expectEmit(address(aToken));
      emit IERC20.Transfer(address(0), user, uint256(deltaAmount));
      vm.expectEmit(address(aToken));
      emit IScaledBalanceToken.Mint(user, user, uint256(deltaAmount), balanceIncrease, newIndex);
      vm.expectEmit(address(underlyingToken));
      emit IERC20.Transfer(aTokenAddress, user, amount);
    } else {
      vm.expectEmit(address(aToken));
      emit IERC20.Transfer(user, address(0), uint256(-deltaAmount));
      vm.expectEmit(address(aToken));
      emit IScaledBalanceToken.Burn(user, target, uint256(-deltaAmount), balanceIncrease, newIndex);
      vm.expectEmit(address(underlyingToken));
      emit IERC20.Transfer(aTokenAddress, user, amount);
    }
  }

  function _generateInterestsByBorrow() internal {
    vm.startPrank(bob);

    contracts.poolProxy.supply(tokenList.usdx, 2000e6, bob, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 400e6, 2, 0, bob);
    vm.warp(vm.getBlockTimestamp() + 64000);

    vm.stopPrank();
  }

  function test_atoken_mintEvents_firstSupply() public {
    uint256 supplyAmount = 1200e6;
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
  }

  function test_atoken_mintEvents_supplyAfterBorrow() public {
    uint256 supplyAmount = 1200e6;

    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);

    _generateInterestsByBorrow();

    vm.startPrank(alice);
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, true);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.warp(vm.getBlockTimestamp() + 64000);

    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, true);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.stopPrank();
  }

  function test_atoken_burnEvents_singleWithdraw_noInterests() public {
    uint256 supplyAmount = 1200e6;
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.warp(vm.getBlockTimestamp() + 48000);

    _expectATokenWithdrawEvents(
      tokenList.usdx,
      address(aToken),
      alice,
      alice,
      supplyAmount,
      false,
      false
    );
    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.usdx, supplyAmount, alice);
  }

  function test_atoken_burnEvents_singleWithdraw_WithInterests() public {
    _generateInterestsByBorrow();

    uint256 supplyAmount = 1200e6;
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.warp(vm.getBlockTimestamp() + 48000);

    _expectATokenWithdrawEvents(
      tokenList.usdx,
      address(aToken),
      alice,
      alice,
      supplyAmount,
      false,
      true
    );
    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.usdx, supplyAmount, alice);
  }

  function test_atoken_burnEvents_withdrawAmountLessThanInterests() public {
    _generateInterestsByBorrow();

    uint256 supplyAmount = 1200e6;
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.warp(vm.getBlockTimestamp() + 48000);

    _expectATokenWithdrawEvents(tokenList.usdx, address(aToken), alice, alice, 10, true, true);
    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.usdx, 10, alice);
  }

  function test_atoken_burnEvents_multipleWithdrawals_withInterests() public {
    _generateInterestsByBorrow();

    uint256 supplyAmount = 1200e6;
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.warp(vm.getBlockTimestamp() + 48000);

    uint256 partialWithdrawAmount = aToken.balanceOf(alice) / 2;
    _expectATokenWithdrawEvents(
      tokenList.usdx,
      address(aToken),
      alice,
      alice,
      partialWithdrawAmount,
      false,
      true
    );
    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.usdx, partialWithdrawAmount, alice);
    vm.warp(vm.getBlockTimestamp() + 48000);

    uint256 secondPartialWithdrawAmount = aToken.balanceOf(alice) / 2;
    _expectATokenWithdrawEvents(
      tokenList.usdx,
      address(aToken),
      alice,
      alice,
      secondPartialWithdrawAmount,
      false,
      true
    );
    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.usdx, secondPartialWithdrawAmount, alice);
    vm.warp(vm.getBlockTimestamp() + 48000);
  }

  function test_atoken_burnEvents_fullBalance() public {
    _generateInterestsByBorrow();

    uint256 supplyAmount = 1200e6;
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.warp(vm.getBlockTimestamp() + 48000);

    uint256 fullBalance = aToken.balanceOf(alice);
    _expectATokenWithdrawEvents(
      tokenList.usdx,
      address(aToken),
      alice,
      alice,
      fullBalance,
      false,
      true
    );
    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.usdx, fullBalance, alice);
  }

  function test_mintToTreasury_events() public {
    uint256 amountToMint = 123e6;

    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(address(0), aToken.RESERVE_TREASURY_ADDRESS(), amountToMint);

    vm.expectEmit(address(aToken));
    emit IScaledBalanceToken.Mint(
      address(contracts.poolProxy),
      aToken.RESERVE_TREASURY_ADDRESS(),
      amountToMint,
      0,
      1e27
    );

    vm.prank(address(contracts.poolProxy));
    aToken.mintToTreasury(amountToMint, 1e27);
  }
}
