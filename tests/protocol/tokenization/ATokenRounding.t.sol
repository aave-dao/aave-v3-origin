// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {ATokenInstance} from '../../../src/contracts/instances/ATokenInstance.sol';
import {TestnetProcedures, TestVars} from '../../utils/TestnetProcedures.sol';
import {AaveSetters} from '../../utils/AaveSetters.sol';
import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';

contract ATokenRoundingTest is TestnetProcedures {
  using WadRayMath for uint256;

  address internal user;

  address internal asset;
  address internal aToken;

  function setUp() external {
    initTestEnvironment();
    asset = tokenList.weth;

    aToken = contracts.poolProxy.getReserveAToken(asset);

    user = alice;
  }

  function test_balanceShouldRoundDown() external {
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 1e27);
    AaveSetters.setATokenBalance(aToken, user, 1, 1e27);

    // user balance should be rounded down
    // 1 * 1e27 / 1e27 = 1
    assertEq(IAToken(aToken).balanceOf(user), 1);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 1e27 + 1);
    // user balance should be rounded down
    // 1 * (1e27 + 1) / 1e27 = 1.000000000000000000000000001
    assertEq(IAToken(aToken).balanceOf(user), 1);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 1e27 - 1);
    // user balance should be rounded down
    // 1 * (1e27 - 1) / 1e27 = 0.999999999999999999999999999
    assertEq(IAToken(aToken).balanceOf(user), 0);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 2e27 - 1);
    // user balance should be rounded down
    // 1 * (2e27 - 1) / 1e27 = 1.999999999999999999999999999
    assertEq(IAToken(aToken).balanceOf(user), 1);
  }

  function test_totalSupplyShouldRoundDown() external {
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 1e27);
    AaveSetters.setATokenTotalSupply(aToken, 1);

    // total supply should be rounded down
    // 1 * 1e27 / 1e27 = 1
    assertEq(IAToken(aToken).totalSupply(), 1);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 1e27 + 1);
    // total supply should be rounded down
    // 1 * (1e27 + 1) / 1e27 = 1.000000000000000000000000001
    assertEq(IAToken(aToken).totalSupply(), 1);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 1e27 - 1);
    // total supply should be rounded down
    // 1 * (1e27 - 1) / 1e27 = 0.999999999999999999999999999
    assertEq(IAToken(aToken).totalSupply(), 0);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 2e27 - 1);
    // total supply should be rounded down
    // 1 * (2e27 - 1) / 1e27 = 1.999999999999999999999999999
    assertEq(IAToken(aToken).totalSupply(), 1);
  }

  function test_supplyShouldRoundDown_revertIfZero() external {
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 1e27 + 1);

    uint256 supplyAmount = 1;

    vm.startPrank(user);
    deal(asset, user, supplyAmount);
    IERC20(asset).approve(report.poolProxy, supplyAmount);

    // user scaled balance should be rounded down
    // 1 * 1e27 / (1e27 + 1) = 0.9999999999999999999999999990...

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAmount.selector));
    contracts.poolProxy.supply({
      asset: asset,
      amount: supplyAmount,
      onBehalfOf: user,
      referralCode: 0
    });
  }

  function test_supplyShouldRoundDown() external {
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 2e27 + 1);

    uint256 supplyAmount = 4;

    vm.startPrank(user);
    deal(asset, user, supplyAmount);
    IERC20(asset).approve(report.poolProxy, supplyAmount);

    // user scaled balance should be rounded down
    // 4 * 1e27 / (2e27 + 1) = 1.9999999999999999999999999990...

    // user balance should be rounded down
    // 1 * (2e27 + 1) / 1e27 = 2.000000000000000000000000001

    contracts.poolProxy.supply({
      asset: asset,
      amount: supplyAmount,
      onBehalfOf: user,
      referralCode: 0
    });

    assertEq(IAToken(aToken).scaledBalanceOf(user), 1);
    assertEq(IAToken(aToken).balanceOf(user), 2);
    assertEq(IAToken(aToken).totalSupply(), 2);
  }

  function test_withdrawShouldRoundUp() external {
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 2e27 + 1);

    uint256 supplyAmount = 8;

    vm.startPrank(user);
    deal(asset, user, supplyAmount);
    IERC20(asset).approve(report.poolProxy, supplyAmount);

    // user scaled balance should be rounded down
    // 8 * 1e27 / (2e27 + 1) = 3.9999999999999999999999999980...

    // user balance should be rounded down
    // 3 * (2e27 + 1) / 1e27 = 6.000000000000000000000000003

    contracts.poolProxy.supply({
      asset: asset,
      amount: supplyAmount,
      onBehalfOf: user,
      referralCode: 0
    });

    assertEq(IAToken(aToken).scaledBalanceOf(user), 3);
    assertEq(IAToken(aToken).balanceOf(user), 6);
    assertEq(IAToken(aToken).totalSupply(), 6);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 3e27 - 1);

    // user balance should be rounded down
    // 3 * (3e27 - 1) / 1e27 = 8.999999999999999999999999997

    assertEq(IAToken(aToken).scaledBalanceOf(user), 3);
    assertEq(IAToken(aToken).balanceOf(user), 8);
    assertEq(IAToken(aToken).totalSupply(), 8);

    uint256 withdrawAmount = 9;

    vm.expectRevert(abi.encodeWithSelector(Errors.NotEnoughAvailableUserBalance.selector));
    contracts.poolProxy.withdraw({asset: asset, amount: withdrawAmount, to: user});

    withdrawAmount = 4;

    // withdraw scaled amount should be rounded up
    // 4 * 1e27 / (3e27 - 1) = 1.33333333333333333333333333377777777777777777777777777792592592592592592592...
    // scaled up to 2

    // user balance after withdrawal should be rounded down
    // 1 * (3e27 - 1) / 1e27 = 2.999999999999999999999999999

    contracts.poolProxy.withdraw({asset: asset, amount: withdrawAmount, to: user});

    assertEq(IAToken(aToken).scaledBalanceOf(user), 1);
    assertEq(IAToken(aToken).balanceOf(user), 2);
    assertEq(IAToken(aToken).totalSupply(), 2);
  }

  function test_transferAmountShouldBeRoundedUp() external {
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 2e27 + 1);

    uint256 supplyAmount = 8;

    vm.startPrank(user);
    deal(asset, user, supplyAmount);
    IERC20(asset).approve(report.poolProxy, supplyAmount);

    // user scaled balance should be rounded down
    // 8 * 1e27 / (2e27 + 1) = 3.9999999999999999999999999980...

    // user balance should be rounded down
    // 3 * (2e27 + 1) / 1e27 = 6.000000000000000000000000003

    contracts.poolProxy.supply({
      asset: asset,
      amount: supplyAmount,
      onBehalfOf: user,
      referralCode: 0
    });

    assertEq(IAToken(aToken).scaledBalanceOf(user), 3);
    assertEq(IAToken(aToken).balanceOf(user), 6);
    assertEq(IAToken(aToken).totalSupply(), 6);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 3e27 - 1);

    // user balance should be rounded down
    // 3 * (3e27 - 1) / 1e27 = 8.999999999999999999999999997

    assertEq(IAToken(aToken).scaledBalanceOf(user), 3);
    assertEq(IAToken(aToken).balanceOf(user), 8);
    assertEq(IAToken(aToken).totalSupply(), 8);

    uint256 transferAmount = 8;

    // transfer scaled amount should be rounded up
    // 8 * 1e27 / (3e27 - 1) = 2.6666666666666666666666666675...
    // scaled up to 3

    // bob balance should be rounded down
    // 3 * (3e27 - 1) / 1e27 = 8.999999999999999999999999997

    IAToken(aToken).transfer(bob, transferAmount);
    vm.stopPrank();

    assertEq(IAToken(aToken).scaledBalanceOf(user), 0);
    assertEq(IAToken(aToken).balanceOf(user), 0);
    assertEq(IAToken(aToken).scaledBalanceOf(bob), 3);
    assertEq(IAToken(aToken).balanceOf(bob), 8);
    assertEq(IAToken(aToken).totalSupply(), 8);

    transferAmount = 4;

    // transfer scaled amount should be rounded up
    // 4 * 1e27 / (3e27 - 1) = 1.3333333333333333333333333337...
    // scaled up to 2

    // user balance should be rounded down
    // 2 * (3e27 - 1) / 1e27 = 5.999999999999999999999999998

    // bob balance should be rounded down
    // 1 * (3e27 - 1) / 1e27 = 2.999999999999999999999999999

    vm.startPrank(bob);
    IAToken(aToken).transfer(user, transferAmount);

    assertEq(IAToken(aToken).scaledBalanceOf(user), 2);
    assertEq(IAToken(aToken).balanceOf(user), 5);
    assertEq(IAToken(aToken).scaledBalanceOf(bob), 1);
    assertEq(IAToken(aToken).balanceOf(bob), 2);
    assertEq(IAToken(aToken).totalSupply(), 8);
  }

  function test_fuzzEdge(uint256 index, uint256 amount, uint256 amountToWithdraw) external {
    index = bound(index, 1e27, 100e27);
    amount = bound(amount, 1, type(uint96).max);
    amountToWithdraw = bound(amountToWithdraw, 1, amount);

    vm.startPrank(user);
    deal(asset, user, amount);
    IERC20(asset).approve(report.poolProxy, amount);
    contracts.poolProxy.supply(asset, amount, user, 0);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, index);
    uint256 aBalanceBefore = IAToken(aToken).balanceOf(user);
    contracts.poolProxy.withdraw(asset, amountToWithdraw, user);
    uint256 aBalanceAfter = IAToken(aToken).balanceOf(user);
    uint256 balanceAfter = IERC20(asset).balanceOf(user);
    assertGe(aBalanceBefore, aBalanceAfter + balanceAfter);
  }
}
