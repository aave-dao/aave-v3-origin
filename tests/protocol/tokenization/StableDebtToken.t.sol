// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {StableDebtTokenHarness as StableDebtTokenInstance} from '../../harness/StableDebtToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IAaveIncentivesController} from '../../../src/contracts/interfaces/IAaveIncentivesController.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {PoolConfigurator, ConfiguratorInputTypes, IPool} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';
import {TestnetProcedures, TestVars} from '../../utils/TestnetProcedures.sol';

contract StableDebtTokenEventsTests is TestnetProcedures {
  StableDebtTokenInstance public stableDebtToken;

  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol,
    bytes params
  );

  event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address indexed asset,
    uint256 amount
  );

  function setUp() public {
    initTestEnvironment();

    (, address stableDebtUsdx, ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );

    stableDebtToken = StableDebtTokenInstance(stableDebtUsdx);

    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.usdx, 10000e6, bob, 0);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 100e8, alice, 0);
    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.wbtc, 100e8, alice, 0);
    // Allow USDX for stable borrow
    vm.prank(poolAdmin);
    PoolConfigurator(report.poolConfiguratorProxy).setReserveStableRateBorrowing(
      tokenList.usdx,
      true
    );
  }

  function test_new_StableDebtToken_implementation() public returns (StableDebtTokenInstance) {
    StableDebtTokenInstance stDebtToken = new StableDebtTokenInstance(IPool(report.poolProxy));

    assertEq(stDebtToken.name(), 'STABLE_DEBT_TOKEN_IMPL');
    assertEq(stDebtToken.symbol(), 'STABLE_DEBT_TOKEN_IMPL');
    assertEq(stDebtToken.decimals(), 0);
    assertEq(address(stDebtToken.POOL()), address(report.poolProxy));
    assertEq(address(stDebtToken.getIncentivesController()), address(0));
    assertEq(stDebtToken.UNDERLYING_ASSET_ADDRESS(), address(0));
    assertEq(stDebtToken.DEBT_TOKEN_REVISION(), 0x1);
    assertEq(stDebtToken.getAverageStableRate(), 0);

    return stDebtToken;
  }

  function test_reverts_initialize_twice(TestVars memory t) public {
    StableDebtTokenInstance staDebtToken = test_initialize_StableDebtToken(t);
    ConfiguratorInputTypes.InitReserveInput memory listing = _generateInitReserveInput(
      t,
      report,
      poolAdmin,
      true
    );

    uint8 decimals = TestnetERC20(listing.underlyingAsset).decimals();

    vm.expectRevert(bytes('Contract instance has already been initialized'));

    staDebtToken.initialize(
      IPool(report.poolProxy),
      listing.underlyingAsset,
      IAaveIncentivesController(listing.incentivesController),
      decimals,
      listing.stableDebtTokenSymbol,
      listing.stableDebtTokenSymbol,
      listing.params
    );
  }

  function test_initialize_StableDebtToken(
    TestVars memory t
  ) public returns (StableDebtTokenInstance) {
    StableDebtTokenInstance stDebtToken = test_new_StableDebtToken_implementation();
    ConfiguratorInputTypes.InitReserveInput memory listing = _generateInitReserveInput(
      t,
      report,
      poolAdmin,
      true
    );

    vm.expectEmit(address(stDebtToken));
    emit Initialized(
      listing.underlyingAsset,
      report.poolProxy,
      report.rewardsControllerProxy,
      TestnetERC20(listing.underlyingAsset).decimals(),
      listing.stableDebtTokenName,
      listing.stableDebtTokenSymbol,
      listing.params
    );

    stDebtToken.initialize(
      IPool(report.poolProxy),
      listing.underlyingAsset,
      IAaveIncentivesController(listing.incentivesController),
      TestnetERC20(listing.underlyingAsset).decimals(),
      listing.stableDebtTokenName,
      listing.stableDebtTokenSymbol,
      listing.params
    );

    assertEq(stDebtToken.name(), listing.stableDebtTokenName);
    assertEq(stDebtToken.symbol(), listing.stableDebtTokenSymbol);
    assertEq(stDebtToken.decimals(), TestnetERC20(listing.underlyingAsset).decimals());
    assertEq(address(stDebtToken.POOL()), address(report.poolProxy));
    assertEq(address(stDebtToken.getIncentivesController()), listing.incentivesController);
    assertEq(stDebtToken.UNDERLYING_ASSET_ADDRESS(), listing.underlyingAsset);
    assertEq(stDebtToken.DEBT_TOKEN_REVISION(), 0x1);

    return stDebtToken;
  }

  function test_reverts_initialize_pool_do_not_match(TestVars memory t) public {
    StableDebtTokenInstance stDebtToken = test_new_StableDebtToken_implementation();
    ConfiguratorInputTypes.InitReserveInput memory listing = _generateInitReserveInput(
      t,
      report,
      poolAdmin,
      true
    );

    uint8 decimals = TestnetERC20(listing.underlyingAsset).decimals();

    vm.expectRevert(bytes(Errors.POOL_ADDRESSES_DO_NOT_MATCH));

    stDebtToken.initialize(
      IPool(makeAddr('ANY_OTHER_POOL')),
      listing.underlyingAsset,
      IAaveIncentivesController(listing.incentivesController),
      decimals,
      listing.stableDebtTokenName,
      listing.stableDebtTokenSymbol,
      listing.params
    );
  }

  function test_mint_stableDebt_caller_alice(TestVars memory t) public {
    StableDebtTokenInstance debtToken = test_initialize_StableDebtToken(t);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(report.poolProxy);
    debtToken.mint(alice, alice, 0, 0);
  }

  function test_mint_stableDebt_caller_bob_onBehalf_alice(TestVars memory t) public {
    StableDebtTokenInstance debtToken = test_initialize_StableDebtToken(t);
    TestnetERC20 asset = TestnetERC20(debtToken.UNDERLYING_ASSET_ADDRESS());
    uint8 decimals = asset.decimals();
    uint256 amount = 1200 * 10 ** decimals;

    vm.expectEmit(address(debtToken));
    emit BorrowAllowanceDelegated(alice, bob, address(asset), amount);

    vm.prank(alice);
    debtToken.approveDelegation(bob, amount);

    vm.prank(report.poolProxy);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    debtToken.mint(bob, alice, amount, 1e27);
  }

  function test_reverts_operation_not_supported() public {
    StableDebtTokenInstance stDebtToken = test_new_StableDebtToken_implementation();

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    stDebtToken.transfer(address(0), 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    stDebtToken.allowance(address(0), address(0));

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    stDebtToken.approve(address(0), 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    stDebtToken.transferFrom(address(0), address(0), 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    stDebtToken.increaseAllowance(address(0), 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    stDebtToken.decreaseAllowance(address(0), 0);

    vm.prank(report.poolProxy);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    stDebtToken.mint(address(0), address(0), 0, 0);

    vm.prank(report.poolProxy);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    stDebtToken.burn(address(0), 0);
  }

  function test_getAverageStableRate() public {
    uint256 avgStableRate = stableDebtToken.getAverageStableRate();
    assertEq(avgStableRate, 0);
  }

  function test_getUserLastUpdated() public {
    uint256 lastUpdated = stableDebtToken.getUserLastUpdated(alice);
    assertEq(lastUpdated, 0);
  }

  function test_getUserStableRate() public {
    uint256 userStableRate = stableDebtToken.getUserStableRate(alice);
    assertEq(userStableRate, 0);
  }

  function test_balanceOf() public {
    uint256 balance = stableDebtToken.balanceOf(alice);
    assertEq(balance, 0);
  }

  function test_totalSupply() public {
    uint256 scaledTotalSupply = stableDebtToken.totalSupply();
    assertEq(scaledTotalSupply, 0);
  }

  function test_getTotalSupplyLastUpdated() public {
    uint256 totalSupplyLastUpdated = stableDebtToken.getTotalSupplyLastUpdated();
    assertEq(totalSupplyLastUpdated, 0);
  }

  function test_principalBalanceOf() public {
    uint256 principalBalanceOf = stableDebtToken.principalBalanceOf(alice);
    assertEq(principalBalanceOf, 0);
  }

  function test_getTotalSupplyAndAvgRate() public {
    (uint256 totalSupply, uint256 avgRate) = stableDebtToken.getTotalSupplyAndAvgRate();
    assertEq(totalSupply, 0);
    assertEq(avgRate, 0);
  }

  function test_getSupplyData() public {
    (
      uint256 principal,
      uint256 totalSupply,
      uint256 avgStableRate,
      uint40 lastUpdatedTimestamp
    ) = stableDebtToken.getSupplyData();

    assertEq(principal, 0);
    assertEq(totalSupply, 0);
    assertEq(avgStableRate, 0);
    assertEq(lastUpdatedTimestamp, 0);
  }

  function test_delegationWithSig() public {
    uint256 amount = 120e6;
    uint256 deadline = block.timestamp + 30 days;

    EIP712SigUtils.CreditDelegation memory delegation = EIP712SigUtils.CreditDelegation({
      delegatee: bob,
      value: amount,
      nonce: 0,
      deadline: deadline
    });

    bytes32 digest = EIP712SigUtils.getCreditDelegationTypedDataHash(
      delegation,
      bytes(stableDebtToken.name()),
      bytes('1'),
      address(stableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    vm.expectEmit(address(stableDebtToken));
    emit BorrowAllowanceDelegated(alice, bob, address(tokenList.usdx), amount);

    vm.prank(alice);
    stableDebtToken.delegationWithSig(alice, bob, amount, deadline, v, r, s);

    assertEq(stableDebtToken.borrowAllowance(alice, bob), amount);
  }

  function test_cancel_delegationWithSig() public {
    // Submit permit by Alice to Bob
    test_delegationWithSig();

    uint256 deadline = block.timestamp + 30 days;

    EIP712SigUtils.CreditDelegation memory delegation = EIP712SigUtils.CreditDelegation({
      delegatee: bob,
      value: 0,
      nonce: 1,
      deadline: deadline
    });

    bytes32 digest = EIP712SigUtils.getCreditDelegationTypedDataHash(
      delegation,
      bytes(stableDebtToken.name()),
      bytes('1'),
      address(stableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertGt(
      stableDebtToken.borrowAllowance(alice, bob),
      0,
      'Alice borrow allowance to bob should be > 0 before cancelling the credit delegation'
    );

    vm.prank(alice);
    stableDebtToken.delegationWithSig(alice, bob, delegation.value, deadline, v, r, s);

    assertEq(
      stableDebtToken.borrowAllowance(alice, bob),
      0,
      'Alice allowance to bob should be zero'
    );
    assertEq(stableDebtToken.nonces(alice), 2, 'Alice nonce does not match expected nonce');
  }

  function test_reverts_bad_nonce_delegationWithSig() public {
    // Submit permit by Alice to Bob
    test_delegationWithSig();

    uint256 deadline = block.timestamp + 30 days;

    EIP712SigUtils.CreditDelegation memory delegation = EIP712SigUtils.CreditDelegation({
      delegatee: bob,
      value: 0,
      nonce: 0, // Wrong nonce, should be 1
      deadline: deadline
    });

    bytes32 digest = EIP712SigUtils.getCreditDelegationTypedDataHash(
      delegation,
      bytes(stableDebtToken.name()),
      bytes('1'),
      address(stableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    vm.expectRevert(bytes(Errors.INVALID_SIGNATURE));

    vm.prank(alice);
    stableDebtToken.delegationWithSig(alice, bob, delegation.value, deadline, v, r, s);
  }

  function test_reverts_bad_expiration_delegationWithSig() public {
    uint256 amount = 120e6;
    uint256 deadline = block.timestamp + 30 days;

    EIP712SigUtils.CreditDelegation memory delegation = EIP712SigUtils.CreditDelegation({
      delegatee: bob,
      value: amount,
      nonce: 0,
      deadline: deadline
    });

    bytes32 digest = EIP712SigUtils.getCreditDelegationTypedDataHash(
      delegation,
      bytes(stableDebtToken.name()),
      bytes('1'),
      address(stableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    vm.warp(delegation.deadline + 1);
    vm.expectRevert(bytes(Errors.INVALID_EXPIRATION));

    vm.prank(alice);
    stableDebtToken.delegationWithSig(alice, bob, amount, deadline, v, r, s);
  }

  function test_reverts_zero_address_delegationWithSig() public {
    uint256 amount = 120e6;
    uint256 deadline = block.timestamp + 30 days;

    EIP712SigUtils.CreditDelegation memory delegation = EIP712SigUtils.CreditDelegation({
      delegatee: bob,
      value: amount,
      nonce: 0,
      deadline: deadline
    });

    bytes32 digest = EIP712SigUtils.getCreditDelegationTypedDataHash(
      delegation,
      bytes(stableDebtToken.name()),
      bytes('1'),
      address(stableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    vm.expectRevert(bytes(Errors.ZERO_ADDRESS_NOT_VALID));

    vm.prank(alice);
    stableDebtToken.delegationWithSig(address(0), bob, amount, deadline, v, r, s);
  }
}
