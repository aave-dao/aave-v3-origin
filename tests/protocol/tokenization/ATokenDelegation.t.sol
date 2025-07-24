// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {ATokenWithDelegationInstance} from '../../../src/contracts/instances/ATokenWithDelegationInstance.sol';
import {IATokenWithDelegation} from '../../../src/contracts/interfaces/IATokenWithDelegation.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {ConfiguratorInputTypes} from '../../../src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {IBaseDelegation} from '../../../src/contracts/protocol/tokenization/delegation/interfaces/IBaseDelegation.sol';

import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract ATokenWithDelegationInstanceNext is ATokenWithDelegationInstance {
  constructor(
    IPool pool,
    address rewardsController,
    address treasury
  ) ATokenWithDelegationInstance(pool, rewardsController, treasury) {}

  function getRevision() internal pure virtual override returns (uint256) {
    return ATOKEN_REVISION + 1;
  }
}

contract ATokenDelegationTest is TestnetProcedures {
  using WadRayMath for uint256;

  address public underlyingAsset;
  ATokenWithDelegationInstance public aToken;

  uint256 public supplyAmount;

  function setUp() public {
    initTestEnvironment();

    _updateATokens();

    underlyingAsset = tokenList.weth;
    aToken = ATokenWithDelegationInstance(contracts.poolProxy.getReserveAToken(underlyingAsset));

    supplyAmount = 1_000_000 * 10 ** IERC20Metadata(underlyingAsset).decimals();

    _supplyAndEnableAsCollateral({user: alice, amount: supplyAmount, asset: underlyingAsset});
  }

  function _updateATokens() private {
    ATokenWithDelegationInstanceNext aTokenImplementation = new ATokenWithDelegationInstanceNext(
      contracts.poolProxy,
      report.rewardsControllerProxy,
      report.treasury
    );

    address[] memory reserves = contracts.poolProxy.getReservesList();

    for (uint256 i = 0; i < reserves.length; ++i) {
      address reserve = reserves[i];

      vm.startPrank(poolAdmin);
      contracts.poolConfiguratorProxy.updateAToken(
        ConfiguratorInputTypes.UpdateATokenInput({
          asset: reserve,
          name: IERC20Metadata(reserve).name(),
          symbol: IERC20Metadata(reserve).symbol(),
          implementation: address(aTokenImplementation),
          params: ''
        })
      );
      vm.stopPrank();
    }
  }

  function test_initial_state_without_delegation() public view {
    address votingDelegatee = aToken.getDelegateeByType(
      alice,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    address propositionDelegatee = aToken.getDelegateeByType(
      alice,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );

    uint256 aliceVotingPower = aToken.getPowerCurrent(
      alice,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    uint256 alicePropositionPower = aToken.getPowerCurrent(
      alice,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );

    uint256 bobVotingPower = aToken.getPowerCurrent(
      bob,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    uint256 bobPropositionPower = aToken.getPowerCurrent(
      bob,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );

    assertEq(votingDelegatee, address(0));
    assertEq(propositionDelegatee, address(0));

    assertEq(aliceVotingPower, supplyAmount);
    assertEq(alicePropositionPower, supplyAmount);

    assertEq(bobVotingPower, 0);
    assertEq(bobPropositionPower, 0);
  }

  function test_delegate() public {
    // from zero address to non zero
    _checkDelegationResult({delegator: alice, newDelegatee: bob});

    // no change with non zero
    _checkDelegationResult({delegator: alice, newDelegatee: bob});

    // from non zero address to non zero
    _checkDelegationResult({delegator: alice, newDelegatee: carol});

    // from non zero address to self
    _checkDelegationResult({delegator: alice, newDelegatee: alice});

    // no change with zero
    _checkDelegationResult({delegator: alice, newDelegatee: address(0)});

    // from non zero address to zero
    _checkDelegationResult({delegator: alice, newDelegatee: bob});
    _checkDelegationResult({delegator: alice, newDelegatee: address(0)});
  }

  function test_transfer() public {
    _supplyAndEnableAsCollateral({user: bob, amount: supplyAmount * 2, asset: underlyingAsset});

    _performTransfersAndChecks({caller: alice, from: alice, to: bob});
  }

  function test_transferFrom() public {
    _supplyAndEnableAsCollateral({user: bob, amount: supplyAmount * 2, asset: underlyingAsset});

    _performTransfersAndChecks({caller: carol, from: alice, to: bob});
  }

  function test_transferOnLiquidation() public {
    _supplyAndEnableAsCollateral({user: bob, amount: supplyAmount * 2, asset: underlyingAsset});

    _performTransfersAndChecks({caller: report.poolProxy, from: alice, to: bob});
  }

  function test_mint_and_burn() public {
    _performTransfersAndChecks({caller: report.poolProxy, from: alice, to: address(0)});
  }

  function _performTransfersAndChecks(address caller, address from, address to) private {
    address user1 = address(12345);
    address user2 = address(123456);
    address user3 = address(1234567);
    address user4 = address(12345678);

    // increase index
    _supplyAndEnableAsCollateral({user: carol, amount: supplyAmount * 2, asset: underlyingAsset});
    vm.prank(carol);
    contracts.poolProxy.borrow({
      asset: underlyingAsset,
      amount: supplyAmount / 10,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: carol
    });
    vm.warp(vm.getBlockTimestamp() + 100 days);

    _checkTransferResult({caller: caller, from: from, to: to, amount: supplyAmount / 2});
    _checkTransferResult({caller: caller, from: from, to: to, amount: type(uint256).max});
    _checkTransferResult({caller: caller, from: to, to: from, amount: supplyAmount});

    // from delegates to user1 and user2
    if (from != address(0)) {
      vm.prank(from);
      aToken.delegateByType(user1, IBaseDelegation.GovernancePowerType.VOTING);
      vm.prank(from);
      aToken.delegateByType(user2, IBaseDelegation.GovernancePowerType.PROPOSITION);
    }

    // to delegates to user3 and user4
    if (to != address(0)) {
      vm.prank(to);
      aToken.delegateByType(user3, IBaseDelegation.GovernancePowerType.VOTING);
      vm.prank(to);
      aToken.delegateByType(user4, IBaseDelegation.GovernancePowerType.PROPOSITION);
    }

    // increase index
    vm.warp(vm.getBlockTimestamp() + 100 days);

    _checkTransferResult({caller: caller, from: from, to: to, amount: supplyAmount / 2});
    _checkTransferResult({caller: caller, from: from, to: to, amount: type(uint256).max});
    _checkTransferResult({caller: caller, from: to, to: from, amount: supplyAmount});

    // from delegates to user3 and user4
    if (from != address(0)) {
      vm.prank(from);
      aToken.delegateByType(user3, IBaseDelegation.GovernancePowerType.VOTING);
      vm.prank(from);
      aToken.delegateByType(user4, IBaseDelegation.GovernancePowerType.PROPOSITION);
    }

    // increase index
    vm.warp(vm.getBlockTimestamp() + 100 days);

    _checkTransferResult({caller: caller, from: from, to: to, amount: supplyAmount / 2});
    _checkTransferResult({caller: caller, from: from, to: to, amount: type(uint256).max});
    _checkTransferResult({caller: caller, from: to, to: from, amount: supplyAmount});

    // from delegates to user3 and user4
    if (from != address(0)) {
      vm.prank(from);
      aToken.delegateByType(user4, IBaseDelegation.GovernancePowerType.VOTING);
      vm.prank(from);
      aToken.delegateByType(user3, IBaseDelegation.GovernancePowerType.PROPOSITION);
    }

    // increase index
    vm.warp(vm.getBlockTimestamp() + 100 days);

    _checkTransferResult({caller: caller, from: from, to: to, amount: supplyAmount / 2});
    _checkTransferResult({caller: caller, from: from, to: to, amount: type(uint256).max});
    _checkTransferResult({caller: caller, from: to, to: from, amount: supplyAmount});

    // to removes delegations
    if (to != address(0)) {
      vm.prank(to);
      aToken.delegate(address(0));
    }

    // increase index
    vm.warp(vm.getBlockTimestamp() + 100 days);

    _checkTransferResult({caller: caller, from: from, to: to, amount: supplyAmount / 2});
    _checkTransferResult({caller: caller, from: from, to: to, amount: type(uint256).max});
    _checkTransferResult({caller: caller, from: to, to: from, amount: supplyAmount});
  }

  function test_getDelegates() public {
    // both to the same zero
    (address votingDelegatee, address propositionDelegatee) = aToken.getDelegates(alice);

    assertEq(votingDelegatee, address(0));
    assertEq(propositionDelegatee, address(0));

    // both to the same non zero
    vm.prank(alice);
    aToken.delegate(bob);

    (votingDelegatee, propositionDelegatee) = aToken.getDelegates(alice);

    assertEq(votingDelegatee, bob);
    assertEq(propositionDelegatee, bob);

    // both to different non zero
    vm.prank(alice);
    aToken.delegateByType(carol, IBaseDelegation.GovernancePowerType.VOTING);

    (votingDelegatee, propositionDelegatee) = aToken.getDelegates(alice);

    assertEq(votingDelegatee, carol);
    assertEq(propositionDelegatee, bob);

    // one to non zero and one to zero
    vm.prank(alice);
    aToken.delegateByType(address(0), IBaseDelegation.GovernancePowerType.PROPOSITION);

    (votingDelegatee, propositionDelegatee) = aToken.getDelegates(alice);

    assertEq(votingDelegatee, carol);
    assertEq(propositionDelegatee, address(0));
  }

  function test_getPowersCurrent() public {
    uint256 aliceBalance = supplyAmount;
    uint256 bobBalance = supplyAmount / 2;
    uint256 carolBalance = supplyAmount * 3;

    _supplyAndEnableAsCollateral({user: bob, amount: bobBalance, asset: underlyingAsset});
    _supplyAndEnableAsCollateral({user: carol, amount: carolBalance, asset: underlyingAsset});

    // alice delegates both types
    vm.prank(alice);
    aToken.delegate(bob);

    // carol delegates only voting
    vm.prank(carol);
    aToken.delegateByType(bob, IBaseDelegation.GovernancePowerType.VOTING);

    (uint256 votingPower, uint256 propositionPower) = aToken.getPowersCurrent(bob);

    assertEq(votingPower, aliceBalance + bobBalance + carolBalance);
    assertEq(votingPower, aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.VOTING));
    assertEq(propositionPower, aliceBalance + bobBalance);
    assertEq(
      propositionPower,
      aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.PROPOSITION)
    );

    // bob delegates voting to carol
    vm.prank(bob);
    aToken.delegateByType(carol, IBaseDelegation.GovernancePowerType.VOTING);

    (votingPower, propositionPower) = aToken.getPowersCurrent(bob);

    assertEq(votingPower, aliceBalance + carolBalance);
    assertEq(votingPower, aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.VOTING));
    assertEq(propositionPower, aliceBalance + bobBalance);
    assertEq(
      propositionPower,
      aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.PROPOSITION)
    );

    // bob delegates proposition to carol
    vm.prank(bob);
    aToken.delegateByType(carol, IBaseDelegation.GovernancePowerType.PROPOSITION);

    (votingPower, propositionPower) = aToken.getPowersCurrent(bob);

    assertEq(votingPower, aliceBalance + carolBalance);
    assertEq(votingPower, aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.VOTING));
    assertEq(propositionPower, aliceBalance);
    assertEq(
      propositionPower,
      aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.PROPOSITION)
    );

    // bob un-delegates voting
    vm.prank(bob);
    aToken.delegateByType(address(0), IBaseDelegation.GovernancePowerType.VOTING);

    (votingPower, propositionPower) = aToken.getPowersCurrent(bob);

    assertEq(votingPower, aliceBalance + carolBalance + bobBalance);
    assertEq(votingPower, aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.VOTING));
    assertEq(propositionPower, aliceBalance);
    assertEq(
      propositionPower,
      aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.PROPOSITION)
    );
  }

  function test_getPowersCurrent_with_index_growth() public {
    uint256 aliceBalance = supplyAmount;
    uint256 bobBalance = supplyAmount / 2;
    uint256 carolBalance = supplyAmount * 3;

    // alice enters with index == 1
    assertEq(contracts.poolProxy.getReserveNormalizedIncome(underlyingAsset), 1e27);

    // alice delegates both types
    vm.prank(alice);
    aToken.delegate(bob);

    // increase index by borrowing and waiting
    vm.prank(alice);
    contracts.poolProxy.borrow({
      asset: underlyingAsset,
      amount: aliceBalance / 10,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: alice
    });
    vm.warp(vm.getBlockTimestamp() + 100 days);

    // bob enters with index > 1
    uint256 bobIndexEnter = contracts.poolProxy.getReserveNormalizedIncome(underlyingAsset);
    assertGt(bobIndexEnter, 1e27);

    _supplyAndEnableAsCollateral({user: bob, amount: bobBalance, asset: underlyingAsset});

    // increase index by waiting
    vm.warp(vm.getBlockTimestamp() + 100 days);

    // carol enters with index > 1 (bigger than bob)
    uint256 carolIndexEnter = contracts.poolProxy.getReserveNormalizedIncome(underlyingAsset);
    assertGt(carolIndexEnter, bobIndexEnter);

    _supplyAndEnableAsCollateral({user: carol, amount: carolBalance, asset: underlyingAsset});

    // carol delegates only voting
    vm.prank(carol);
    aToken.delegateByType(bob, IBaseDelegation.GovernancePowerType.VOTING);

    (uint256 votingPower, uint256 propositionPower) = aToken.getPowersCurrent(bob);

    aliceBalance = aToken.balanceOf(alice);
    bobBalance = aToken.balanceOf(bob);
    carolBalance = aToken.balanceOf(carol);

    assertApproxEqAbs(
      votingPower,
      _getDownscaleVotingPower(alice) +
        aToken.scaledBalanceOf(bob) +
        _getDownscaleVotingPower(carol),
      1,
      '1'
    );
    assertEq(votingPower, aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.VOTING));
    assertApproxEqAbs(
      propositionPower,
      _getDownscaleVotingPower(alice) + aToken.scaledBalanceOf(bob),
      1,
      '2'
    );
    assertEq(
      propositionPower,
      aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.PROPOSITION)
    );

    // increase index by waiting
    vm.warp(vm.getBlockTimestamp() + 100 days);

    (votingPower, propositionPower) = aToken.getPowersCurrent(bob);

    aliceBalance = aToken.balanceOf(alice);
    bobBalance = aToken.balanceOf(bob);
    carolBalance = aToken.balanceOf(carol);

    assertApproxEqAbs(
      votingPower,
      _getDownscaleVotingPower(alice) +
        aToken.scaledBalanceOf(bob) +
        _getDownscaleVotingPower(carol),
      1,
      '3'
    );
    assertEq(votingPower, aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.VOTING));
    assertApproxEqAbs(
      propositionPower,
      _getDownscaleVotingPower(alice) + aToken.scaledBalanceOf(bob),
      1,
      '4'
    );
    assertEq(
      propositionPower,
      aToken.getPowerCurrent(bob, IBaseDelegation.GovernancePowerType.PROPOSITION)
    );
  }

  function test_precision() public {
    assertEq(IERC20Metadata(tokenList.usdx).decimals(), 6);
    assertEq(IERC20Metadata(tokenList.wbtc).decimals(), 8);
    assertEq(IERC20Metadata(tokenList.weth).decimals(), 18);

    IATokenWithDelegation usdxAToken = IATokenWithDelegation(
      contracts.poolProxy.getReserveAToken(tokenList.usdx)
    );
    IATokenWithDelegation wbtcAToken = IATokenWithDelegation(
      contracts.poolProxy.getReserveAToken(tokenList.wbtc)
    );
    IATokenWithDelegation wethAToken = IATokenWithDelegation(
      contracts.poolProxy.getReserveAToken(tokenList.weth)
    );

    uint256 _supplyAmount = 151413121110987654321;

    _supplyAndEnableAsCollateral({user: bob, amount: _supplyAmount, asset: tokenList.usdx});
    _supplyAndEnableAsCollateral({user: bob, amount: _supplyAmount, asset: tokenList.wbtc});
    _supplyAndEnableAsCollateral({user: bob, amount: _supplyAmount, asset: tokenList.weth});

    vm.startPrank(bob);

    usdxAToken.delegate(carol);
    wbtcAToken.delegate(carol);
    wethAToken.delegate(carol);

    vm.stopPrank();

    (uint256 usdxVotingPower, uint256 usdxPropositionPower) = usdxAToken.getPowersCurrent(carol);
    (uint256 wbtcVotingPower, uint256 wbtcPropositionPower) = wbtcAToken.getPowersCurrent(carol);
    (uint256 wethVotingPower, uint256 wethPropositionPower) = wethAToken.getPowersCurrent(carol);

    // token has 6 decimals, need to store all decimals
    assertEq(usdxVotingPower, usdxPropositionPower);
    assertEq(usdxVotingPower, 151413121110000000000);

    // token has 8 decimals, need to store all decimals
    assertEq(wbtcVotingPower, wbtcPropositionPower);
    assertEq(wbtcVotingPower, 151413121110000000000);

    // token has 18 decimals, need to store only first 8 decimals
    assertEq(wethVotingPower, wethPropositionPower);
    assertEq(wethVotingPower, 151413121110000000000);
  }

  function _checkDelegationResult(address delegator, address newDelegatee) private {
    address previousVotingDelegatee = aToken.getDelegateeByType(
      delegator,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    address previousPropositionDelegatee = aToken.getDelegateeByType(
      delegator,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );

    address formattedNewDelegatee = newDelegatee == delegator ? address(0) : newDelegatee;

    if (previousVotingDelegatee != formattedNewDelegatee) {
      vm.expectEmit(address(aToken));
      emit IBaseDelegation.DelegateChanged(
        delegator,
        formattedNewDelegatee,
        IBaseDelegation.GovernancePowerType.VOTING
      );
    }

    if (previousPropositionDelegatee != formattedNewDelegatee) {
      vm.expectEmit(address(aToken));
      emit IBaseDelegation.DelegateChanged(
        delegator,
        formattedNewDelegatee,
        IBaseDelegation.GovernancePowerType.PROPOSITION
      );
    }

    uint256 delegatorBalance = aToken.balanceOf(delegator);

    vm.prank(delegator);
    aToken.delegate(newDelegatee);

    address votingDelegatee = aToken.getDelegateeByType(
      delegator,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    address propositionDelegatee = aToken.getDelegateeByType(
      delegator,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );

    assertEq(votingDelegatee, formattedNewDelegatee);
    assertEq(propositionDelegatee, formattedNewDelegatee);

    uint256 delegatorVotingPower = aToken.getPowerCurrent(
      delegator,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    uint256 delegatorPropositionPower = aToken.getPowerCurrent(
      delegator,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );

    if (newDelegatee == alice || newDelegatee == address(0)) {
      assertEq(delegatorVotingPower, delegatorBalance);
      assertEq(delegatorPropositionPower, delegatorBalance);
    } else {
      assertEq(delegatorVotingPower, 0);
      assertEq(delegatorPropositionPower, 0);

      uint256 newDelegateeVotingPower = aToken.getPowerCurrent(
        newDelegatee,
        IBaseDelegation.GovernancePowerType.VOTING
      );
      uint256 newDelegateePropositionPower = aToken.getPowerCurrent(
        newDelegatee,
        IBaseDelegation.GovernancePowerType.PROPOSITION
      );

      assertEq(newDelegateeVotingPower, delegatorBalance);
      assertEq(newDelegateePropositionPower, delegatorBalance);
    }
  }

  struct CheckTransferResultParams {
    uint256 fromBalanceBefore;
    uint256 fromDownscaledVotingPowerBefore;
    uint256 toBalanceBefore;
    uint256 toDownscaledVotingPowerBefore;
    uint256 fromBalanceAfter;
    uint256 fromDownscaledVotingPowerAfter;
    uint256 toBalanceAfter;
    uint256 toDownscaledVotingPowerAfter;
    uint256 fromDownscaledVotingPowerChange;
    uint256 toDownscaledVotingPowerChange;
    address votingDelegateeFrom;
    address propositionDelegateeFrom;
    address votingDelegateeTo;
    address propositionDelegateeTo;
    uint256 votingPowerDelegateeFromBefore;
    uint256 propositionPowerDelegateeFromBefore;
    uint256 votingPowerDelegateeToBefore;
    uint256 propositionPowerDelegateeToBefore;
    uint256 votingPowerDelegateeFromAfter;
    uint256 propositionPowerDelegateeFromAfter;
    uint256 votingPowerDelegateeToAfter;
    uint256 propositionPowerDelegateeToAfter;
  }

  function _checkTransferResult(address caller, address from, address to, uint256 amount) private {
    CheckTransferResultParams memory params;

    params.fromBalanceBefore = aToken.balanceOf(from);
    params.toBalanceBefore = aToken.balanceOf(to);

    params.fromDownscaledVotingPowerBefore = _getDownscaleVotingPower(from);
    params.toDownscaledVotingPowerBefore = _getDownscaleVotingPower(to);

    if (from != address(0) && amount == type(uint256).max) {
      amount = params.fromBalanceBefore;
    }

    (params.votingDelegateeFrom, params.propositionDelegateeFrom) = aToken.getDelegates(from);
    (params.votingDelegateeTo, params.propositionDelegateeTo) = aToken.getDelegates(to);

    params.votingPowerDelegateeFromBefore = aToken.getPowerCurrent(
      params.votingDelegateeFrom,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    params.propositionPowerDelegateeFromBefore = aToken.getPowerCurrent(
      params.propositionDelegateeFrom,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );
    params.votingPowerDelegateeToBefore = aToken.getPowerCurrent(
      params.votingDelegateeTo,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    params.propositionPowerDelegateeToBefore = aToken.getPowerCurrent(
      params.propositionDelegateeTo,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );

    if (caller != from) {
      if (caller == report.poolProxy) {
        if (from == address(0)) {
          _supplyAndEnableAsCollateral({user: to, amount: amount, asset: underlyingAsset});
        } else if (to == address(0)) {
          vm.prank(from);
          contracts.poolProxy.withdraw({asset: underlyingAsset, amount: amount, to: from});
        } else {
          uint256 index = contracts.poolProxy.getReserveNormalizedIncome(underlyingAsset);

          vm.prank(caller);

          aToken.transferOnLiquidation({
            from: from,
            to: to,
            amount: amount,
            scaledAmount: amount.rayDivCeil(index),
            index: index
          });
        }
      } else {
        vm.prank(from);
        aToken.approve(caller, amount);

        vm.prank(caller);
        aToken.transferFrom(from, to, amount);
      }
    } else {
      vm.prank(from);
      aToken.transfer(to, amount);
    }

    params.fromBalanceAfter = aToken.balanceOf(from);
    params.toBalanceAfter = aToken.balanceOf(to);

    params.fromDownscaledVotingPowerAfter = _getDownscaleVotingPower(from);
    params.toDownscaledVotingPowerAfter = _getDownscaleVotingPower(to);

    params.fromDownscaledVotingPowerChange =
      params.fromDownscaledVotingPowerBefore -
      params.fromDownscaledVotingPowerAfter;
    params.toDownscaledVotingPowerChange =
      params.toDownscaledVotingPowerAfter -
      params.toDownscaledVotingPowerBefore;

    if (from != address(0)) {
      assertApproxEqAbs(params.fromBalanceAfter, params.fromBalanceBefore - amount, 1, 'from');
    } else {
      assertEq(params.fromBalanceBefore, 0);
      assertEq(params.fromBalanceAfter, 0);
    }
    if (to != address(0)) {
      assertApproxEqAbs(params.toBalanceAfter, params.toBalanceBefore + amount, 1, 'to');
    } else {
      assertEq(params.toBalanceBefore, 0);
      assertEq(params.toBalanceAfter, 0);
    }

    params.votingPowerDelegateeFromAfter = aToken.getPowerCurrent(
      params.votingDelegateeFrom,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    params.propositionPowerDelegateeFromAfter = aToken.getPowerCurrent(
      params.propositionDelegateeFrom,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );
    params.votingPowerDelegateeToAfter = aToken.getPowerCurrent(
      params.votingDelegateeTo,
      IBaseDelegation.GovernancePowerType.VOTING
    );
    params.propositionPowerDelegateeToAfter = aToken.getPowerCurrent(
      params.propositionDelegateeTo,
      IBaseDelegation.GovernancePowerType.PROPOSITION
    );

    if (params.votingDelegateeFrom != params.votingDelegateeTo) {
      if (params.votingDelegateeFrom != address(0)) {
        assertApproxEqAbs(
          params.votingPowerDelegateeFromAfter,
          params.votingPowerDelegateeFromBefore - params.fromDownscaledVotingPowerChange,
          1,
          '1'
        );
      }

      if (params.votingDelegateeTo != address(0)) {
        assertApproxEqAbs(
          params.votingPowerDelegateeToAfter,
          params.votingPowerDelegateeToBefore + params.toDownscaledVotingPowerChange,
          1,
          '2'
        );
      }
    } else if (params.votingDelegateeFrom != address(0)) {
      assertApproxEqAbs(
        params.votingPowerDelegateeFromAfter,
        params.fromDownscaledVotingPowerAfter + params.toDownscaledVotingPowerAfter,
        1,
        '5'
      );
      assertEq(params.votingPowerDelegateeToAfter, params.votingPowerDelegateeFromAfter, '6');
    }

    if (params.propositionDelegateeFrom != params.propositionDelegateeTo) {
      if (params.propositionDelegateeFrom != address(0)) {
        assertApproxEqAbs(
          params.propositionPowerDelegateeFromAfter,
          params.propositionPowerDelegateeFromBefore - params.fromDownscaledVotingPowerChange,
          1,
          '3'
        );
      }

      if (params.propositionDelegateeTo != address(0)) {
        assertApproxEqAbs(
          params.propositionPowerDelegateeToAfter,
          params.propositionPowerDelegateeToBefore + params.toDownscaledVotingPowerChange,
          1,
          '4'
        );
      }
    } else if (params.propositionDelegateeFrom != address(0)) {
      assertApproxEqAbs(
        params.propositionPowerDelegateeFromAfter,
        params.fromDownscaledVotingPowerAfter + params.toDownscaledVotingPowerAfter,
        1,
        '7'
      );
      assertEq(
        params.propositionPowerDelegateeToAfter,
        params.propositionPowerDelegateeFromAfter,
        '8'
      );
    }
  }

  function _getDownscaleVotingPower(address user) private view returns (uint256) {
    uint256 scaledBalance = aToken.scaledBalanceOf(user);

    uint256 POWER_SCALE_FACTOR = aToken.POWER_SCALE_FACTOR();

    return (scaledBalance / POWER_SCALE_FACTOR) * POWER_SCALE_FACTOR;
  }
}
