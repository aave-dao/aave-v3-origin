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

contract VariableDebtTokenRoundingTest is TestnetProcedures {
  using WadRayMath for uint256;

  address internal user;

  address internal asset = tokenList.usdx;
  address internal vToken;

  function setUp() external {
    initTestEnvironment();
    asset = tokenList.usdx;

    vToken = contracts.poolProxy.getReserveVariableDebtToken(asset);

    user = alice;

    _supplyAndEnableAsCollateral({user: user, amount: 100 ether, asset: asset});
  }

  function test_balanceShouldRoundUp() external {
    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 1e27);
    AaveSetters.setVariableDebtTokenBalance(vToken, user, 1, 1e27);

    // user balance should be rounded up
    // 1 * 1e27 / 1e27 = 1
    assertEq(IAToken(vToken).balanceOf(user), 1);

    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 1e27 + 1);
    // user balance should be rounded up
    // 1 * (1e27 + 1) / 1e27 = 1.000000000000000000000000001
    assertEq(IAToken(vToken).balanceOf(user), 2);

    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 1e27 - 1);
    // user balance should be rounded up
    // 1 * (1e27 - 1) / 1e27 = 0.999999999999999999999999999
    assertEq(IAToken(vToken).balanceOf(user), 1);

    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 2e27 - 1);
    // user balance should be rounded up
    // 1 * (2e27 - 1) / 1e27 = 1.999999999999999999999999999
    assertEq(IAToken(vToken).balanceOf(user), 2);
  }

  function test_totalSupplyShouldRoundUp() external {
    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 1e27);
    AaveSetters.setVariableDebtTokenTotalSupply(vToken, 1);

    // total supply should be rounded up
    // 1 * 1e27 / 1e27 = 1
    assertEq(IAToken(vToken).totalSupply(), 1);

    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 1e27 + 1);
    // total supply should be rounded up
    // 1 * (1e27 + 1) / 1e27 = 1.000000000000000000000000001
    assertEq(IAToken(vToken).totalSupply(), 2);

    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 1e27 - 1);
    // total supply should be rounded up
    // 1 * (1e27 - 1) / 1e27 = 0.999999999999999999999999999
    assertEq(IAToken(vToken).totalSupply(), 1);

    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 2e27 - 1);
    // total supply should be rounded up
    // 1 * (2e27 - 1) / 1e27 = 1.999999999999999999999999999
    assertEq(IAToken(vToken).totalSupply(), 2);
  }

  function test_borrowShouldRoundUp() external {
    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 2e27 + 1);

    uint256 borrowAmount = 3;

    // user scaled balance should be rounded up
    // 3 * 1e27 / (2e27 + 1) = 1.4999999999999999999999999992500...

    // user balance should be rounded up
    // 2 * (2e27 + 1) / 1e27 = 4.000000000000000000000000002

    vm.startPrank(user);
    contracts.poolProxy.borrow({
      asset: asset,
      amount: borrowAmount,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: user
    });

    assertEq(IAToken(vToken).scaledBalanceOf(user), 2);
    assertEq(IAToken(vToken).balanceOf(user), 5);
    assertEq(IAToken(vToken).totalSupply(), 5);
  }

  function test_repayShouldRoundDown() external {
    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 2e27 + 1);

    uint256 borrowAmount = 7;

    // user scaled balance should be rounded up
    // 7 * 1e27 / (2e27 + 1) = 3.499999999999999999999999...

    // user balance should be rounded up
    // 4 * (2e27 + 1) / 1e27 = 8.000000000000000000000000004

    vm.startPrank(user);
    contracts.poolProxy.borrow({
      asset: asset,
      amount: borrowAmount,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: user
    });

    assertEq(IAToken(vToken).scaledBalanceOf(user), 4);
    assertEq(IAToken(vToken).balanceOf(user), 9);
    assertEq(IAToken(vToken).totalSupply(), 9);

    uint256 repayAmount = 4;

    // repay scaled amount should be rounded down
    // 4 * 1e27 / (2e27 + 1) = 1.9999999999999999999999999...

    // user balance should be rounded up
    // 3 * (2e27 + 1) / 1e27 = 6.000000000000000000000000003

    deal(asset, user, repayAmount);
    IERC20(asset).approve(report.poolProxy, repayAmount);

    contracts.poolProxy.repay({
      asset: asset,
      amount: repayAmount,
      interestRateMode: 2,
      onBehalfOf: user
    });

    assertEq(IAToken(vToken).scaledBalanceOf(user), 3);
    assertEq(IAToken(vToken).balanceOf(user), 7);
    assertEq(IAToken(vToken).totalSupply(), 7);
  }
}
