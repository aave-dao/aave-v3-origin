// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken} from '../../../src/contracts/interfaces/IAToken.sol';
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

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Mint(address indexed token, address indexed to, uint256 amount);
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );
  event Burn(
    address indexed from,
    address indexed target,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  function setUp() public {
    initTestEnvironment();

    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
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

    uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
      reserveData.currentLiquidityRate,
      reserveData.lastUpdateTimestamp
    );
    uint256 index = cumulatedLiquidityInterest.rayMul(reserveData.liquidityIndex);
    uint256 scaledBalance = IAToken(aTokenAddress).scaledBalanceOf(onBehalfOf);
    uint256 balanceIncrease = scaledBalance.rayMul(index) -
      scaledBalance.rayMul(IAToken(aTokenAddress).getPreviousIndex(onBehalfOf));

    if (checkInterestsNonZero) {
      assertTrue(
        balanceIncrease > 0,
        'Intention failed: balanceIncrease should be greater than zero'
      );
    }

    vm.expectEmit(address(underlyingToken));
    emit Transfer(user, aTokenAddress, amount);
    vm.expectEmit(address(aToken));
    emit Transfer(address(0), onBehalfOf, amount + balanceIncrease);
    vm.expectEmit(address(aToken));
    emit Mint(user, onBehalfOf, amount + balanceIncrease, balanceIncrease, index);
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

    uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
      reserveData.currentLiquidityRate,
      reserveData.lastUpdateTimestamp
    );
    uint256 index = cumulatedLiquidityInterest.rayMul(reserveData.liquidityIndex);
    uint256 scaledBalance = IAToken(aTokenAddress).scaledBalanceOf(user);
    uint256 balanceIncrease = scaledBalance.rayMul(index) -
      scaledBalance.rayMul(IAToken(aTokenAddress).getPreviousIndex(user));
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
    if (balanceIncrease > amount) {
      uint256 amountToMint = balanceIncrease - amount;
      vm.expectEmit(address(aToken));
      emit Transfer(address(0), user, amountToMint);
      vm.expectEmit(address(aToken));
      emit Mint(user, user, amountToMint, balanceIncrease, index);
      vm.expectEmit(address(underlyingToken));
      emit Transfer(aTokenAddress, user, amount);
    } else {
      uint256 amountToBurn = amount - balanceIncrease;
      vm.expectEmit(address(aToken));
      emit Transfer(user, address(0), amountToBurn);
      vm.expectEmit(address(aToken));
      emit Burn(user, target, amountToBurn, balanceIncrease, index);
      vm.expectEmit(address(underlyingToken));
      emit Transfer(aTokenAddress, user, amount);
    }
  }

  function _generateInterestsByBorrow() internal {
    vm.startPrank(bob);

    contracts.poolProxy.supply(tokenList.usdx, 2000e6, bob, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 400e6, 2, 0, bob);
    vm.warp(block.timestamp + 64000);

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
    vm.warp(block.timestamp + 64000);

    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, true);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.stopPrank();
  }

  function test_atoken_burnEvents_singleWithdraw_noInterests() public {
    uint256 supplyAmount = 1200e6;
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.warp(block.timestamp + 48000);

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
    vm.warp(block.timestamp + 48000);

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
    vm.warp(block.timestamp + 48000);

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
    vm.warp(block.timestamp + 48000);

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
    vm.warp(block.timestamp + 48000);

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
    vm.warp(block.timestamp + 48000);
  }

  function test_atoken_burnEvents_fullBalance() public {
    _generateInterestsByBorrow();

    uint256 supplyAmount = 1200e6;
    _expectATokenSupplyEvents(tokenList.usdx, address(aToken), alice, alice, supplyAmount, false);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    vm.warp(block.timestamp + 48000);

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
    emit Transfer(address(0), aToken.RESERVE_TREASURY_ADDRESS(), amountToMint);

    vm.expectEmit(address(aToken));
    emit Mint(
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
