// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {L2Encoder} from '../../../src/contracts/helpers/L2Encoder.sol';
import {IL2Pool} from '../../../src/contracts/interfaces/IL2Pool.sol';
import {IReserveInterestRateStrategy} from '../../../src/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {BorrowLogic} from '../../../src/contracts/protocol/libraries/logic/BorrowLogic.sol';
import {SupplyLogic} from '../../../src/contracts/protocol/libraries/logic/SupplyLogic.sol';
import {LiquidationLogic} from '../../../src/contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {PoolTests, DataTypes, Errors, IERC20, IPool} from './Pool.t.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';

/// @dev All Pool.t.sol tests are run as L2Pool via inheriting PoolTests
contract L2PoolTests is PoolTests {
  using stdStorage for StdStorage;

  IL2Pool internal l2Pool;
  L2Encoder internal l2Encoder;

  function setUp() public override {
    initL2TestEnvironment();

    pool = IPool(report.poolProxy);
    l2Pool = IL2Pool(report.poolProxy);
    l2Encoder = L2Encoder(report.l2Encoder);
  }

  function test_l2_supply() public {
    bytes32 encodedInput = l2Encoder.encodeSupplyParams(tokenList.usdx, 1e6, 0);

    vm.expectEmit(report.poolProxy);
    emit SupplyLogic.Supply(tokenList.usdx, alice, alice, 1e6, 0);

    vm.prank(alice);
    l2Pool.supply(encodedInput);
  }

  function test_l2_supply_permit(uint128 userPk, uint128 supplyAmount) public {
    vm.assume(userPk != 0);
    vm.assume(supplyAmount != 0);
    address user = vm.addr(userPk);
    deal(tokenList.usdx, user, supplyAmount);

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: user,
      spender: address(contracts.poolProxy),
      value: supplyAmount,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(TestnetERC20(tokenList.usdx).name()),
      bytes('1'),
      tokenList.usdx
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    vm.expectEmit(report.poolProxy);
    emit SupplyLogic.ReserveUsedAsCollateralEnabled(tokenList.usdx, user);
    vm.expectEmit(report.poolProxy);
    emit SupplyLogic.Supply(tokenList.usdx, user, user, supplyAmount, 0);

    (bytes32 encodedInput1, bytes32 encodedInput2, bytes32 encodedInput3) = l2Encoder
      .encodeSupplyWithPermitParams(tokenList.usdx, permit.value, 0, permit.deadline, v, r, s);

    vm.prank(user);
    l2Pool.supplyWithPermit(encodedInput1, encodedInput2, encodedInput3);
  }

  function test_l2_withdraw() public {
    test_l2_supply();

    bytes32 encodedInput = l2Encoder.encodeWithdrawParams(tokenList.usdx, UINT256_MAX);
    vm.expectEmit(report.poolProxy);
    emit Withdraw(tokenList.usdx, alice, alice, 1e6);

    vm.prank(alice);
    l2Pool.withdraw(encodedInput);
  }

  function test_l2_partial_withdraw() public {
    test_l2_supply();

    bytes32 encodedInput = l2Encoder.encodeWithdrawParams(tokenList.usdx, 0.5e6);
    vm.expectEmit(report.poolProxy);
    emit Withdraw(tokenList.usdx, alice, alice, 0.5e6);

    vm.prank(alice);
    l2Pool.withdraw(encodedInput);
  }

  function test_l2_borrow() public {
    test_l2_supply();

    bytes32 encodedInput = l2Encoder.encodeBorrowParams(tokenList.usdx, 0.2e6, 2, 0);

    vm.expectEmit(address(contracts.poolProxy));
    emit BorrowLogic.Borrow(
      tokenList.usdx,
      alice,
      alice,
      0.2e6,
      DataTypes.InterestRateMode(2),
      _calculateInterestRates(0.2e6, tokenList.usdx),
      0
    );

    vm.prank(alice);
    l2Pool.borrow(encodedInput);
  }

  function test_l2_repay() public {
    test_l2_borrow();

    bytes32 encodedInput = l2Encoder.encodeRepayParams(tokenList.usdx, UINT256_MAX, 2);

    vm.prank(alice);
    l2Pool.repay(encodedInput);
  }

  function test_l2_repay_permit(
    uint128 userPk,
    uint128 supplyAmount,
    uint128 underlyingBalance,
    uint128 borrowAmount,
    uint128 repayAmount
  ) public {
    vm.assume(userPk != 0);
    underlyingBalance = uint128(bound(underlyingBalance, 2, type(uint120).max));
    supplyAmount = uint128(bound(supplyAmount, 2, underlyingBalance));
    borrowAmount = uint128(bound(borrowAmount, 1, supplyAmount / 2));
    repayAmount = uint128(bound(repayAmount, 1, borrowAmount));

    address user = vm.addr(userPk);
    deal(tokenList.usdx, user, underlyingBalance);
    vm.startPrank(user);

    usdx.approve(address(contracts.poolProxy), supplyAmount);
    pool.supply(tokenList.usdx, supplyAmount, user, 0);
    pool.borrow(tokenList.usdx, borrowAmount, 2, 0, user);
    vm.warp(block.timestamp + 10 days);

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: user,
      spender: address(contracts.poolProxy),
      value: repayAmount,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(TestnetERC20(tokenList.usdx).name()),
      bytes('1'),
      tokenList.usdx
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(tokenList.usdx, user, user, permit.value, false);

    (bytes32 encodedInput1, bytes32 encodedInput2, bytes32 encodedInput3) = l2Encoder
      .encodeRepayWithPermitParams(tokenList.usdx, permit.value, 2, permit.deadline, v, r, s);

    l2Pool.repayWithPermit(encodedInput1, encodedInput2, encodedInput3);
    vm.stopPrank();
  }

  function test_l2_repay_atokens() public {
    test_l2_borrow();
    bytes32 encodedInput = l2Encoder.encodeRepayWithATokensParams(tokenList.usdx, UINT256_MAX, 2);

    vm.prank(alice);
    l2Pool.repayWithATokens(encodedInput);
  }

  function test_l2_set_user_collateral() public {
    test_l2_supply();

    bytes32 encodedInput = l2Encoder.encodeSetUserUseReserveAsCollateral(tokenList.usdx, false);
    vm.prank(alice);
    l2Pool.setUserUseReserveAsCollateral(encodedInput);
  }

  function test_l2_liquidationCall() public {
    vm.startPrank(carol);

    pool.supply(tokenList.usdx, 100_000e6, carol, 0);
    pool.supply(tokenList.wbtc, 100e8, carol, 0);

    vm.stopPrank();
    vm.startPrank(alice);

    pool.supply(tokenList.wbtc, 1e8, alice, 0);
    pool.borrow(tokenList.usdx, 20500e6, 2, 0, alice);
    vm.warp(block.timestamp + 30 days);
    pool.borrow(tokenList.wbtc, 0.002e8, 2, 0, alice);
    vm.warp(block.timestamp + 30 days);

    vm.stopPrank();

    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.wbtc))
      .sig('_latestAnswer()')
      .checked_write(
        _calcPrice(IAaveOracle(report.aaveOracle).getAssetPrice(tokenList.wbtc), 30_00)
      );

    vm.expectEmit(true, true, true, false, address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(tokenList.wbtc, tokenList.usdx, alice, 0, 0, bob, false);

    (bytes32 encodedInput1, bytes32 encodedInput2) = l2Encoder.encodeLiquidationCall(
      tokenList.wbtc,
      tokenList.usdx,
      alice,
      UINT256_MAX,
      false
    );

    // Liquidate
    vm.prank(bob);
    l2Pool.liquidationCall(encodedInput1, encodedInput2);
  }
}
