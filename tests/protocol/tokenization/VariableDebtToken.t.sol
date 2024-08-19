// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {VariableDebtTokenHarness as VariableDebtTokenInstance} from '../../harness/VariableDebtToken.sol';
import {IAaveIncentivesController} from '../../../src/contracts/interfaces/IAaveIncentivesController.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {ReserveLogic, DataTypes} from '../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {ConfiguratorInputTypes, IPool} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';
import {TestnetProcedures, TestVars} from '../../utils/TestnetProcedures.sol';

contract VariableDebtTokenEventsTests is TestnetProcedures {
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;

  VariableDebtTokenInstance public variableDebtToken;

  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol,
    bytes params
  );

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

  event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address indexed asset,
    uint256 amount
  );

  function setUp() public {
    initTestEnvironment();

    (, , address variableDebtUsdx) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );

    variableDebtToken = VariableDebtTokenInstance(variableDebtUsdx);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 10000e6, alice, 0);
    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.usdx, 10000e6, bob, 0);
  }

  function test_new_VariableDebtToken_implementation() public returns (VariableDebtTokenInstance) {
    VariableDebtTokenInstance varDebtToken = new VariableDebtTokenInstance(IPool(report.poolProxy));

    assertEq(varDebtToken.name(), 'VARIABLE_DEBT_TOKEN_IMPL');
    assertEq(varDebtToken.symbol(), 'VARIABLE_DEBT_TOKEN_IMPL');
    assertEq(varDebtToken.decimals(), 0);
    assertEq(address(varDebtToken.POOL()), address(report.poolProxy));
    assertEq(address(varDebtToken.getIncentivesController()), address(0));
    assertEq(varDebtToken.UNDERLYING_ASSET_ADDRESS(), address(0));
    assertEq(varDebtToken.DEBT_TOKEN_REVISION(), 0x1);

    return varDebtToken;
  }

  function test_initialize_VariableDebtToken(
    TestVars memory t
  ) public returns (VariableDebtTokenInstance) {
    VariableDebtTokenInstance varDebtToken = test_new_VariableDebtToken_implementation();
    ConfiguratorInputTypes.InitReserveInput memory listing = _generateInitReserveInput(
      t,
      report,
      poolAdmin,
      true
    );

    vm.expectEmit(address(varDebtToken));
    emit Initialized(
      listing.underlyingAsset,
      report.poolProxy,
      listing.incentivesController,
      TestnetERC20(listing.underlyingAsset).decimals(),
      listing.variableDebtTokenName,
      listing.variableDebtTokenSymbol,
      listing.params
    );

    varDebtToken.initialize(
      IPool(report.poolProxy),
      listing.underlyingAsset,
      IAaveIncentivesController(listing.incentivesController),
      TestnetERC20(listing.underlyingAsset).decimals(),
      listing.variableDebtTokenName,
      listing.variableDebtTokenSymbol,
      listing.params
    );

    assertEq(varDebtToken.name(), listing.variableDebtTokenName);
    assertEq(varDebtToken.symbol(), listing.variableDebtTokenSymbol);
    assertEq(varDebtToken.decimals(), TestnetERC20(listing.underlyingAsset).decimals());
    assertEq(address(varDebtToken.POOL()), address(report.poolProxy));
    assertEq(address(varDebtToken.getIncentivesController()), listing.incentivesController);
    assertEq(varDebtToken.UNDERLYING_ASSET_ADDRESS(), listing.underlyingAsset);
    assertEq(varDebtToken.DEBT_TOKEN_REVISION(), 0x1);

    return varDebtToken;
  }

  function test_reverts_initialize_twice(TestVars memory t) public {
    VariableDebtTokenInstance varDebtToken = test_initialize_VariableDebtToken(t);
    ConfiguratorInputTypes.InitReserveInput memory listing = _generateInitReserveInput(
      t,
      report,
      poolAdmin,
      true
    );

    uint8 decimals = TestnetERC20(listing.underlyingAsset).decimals();

    vm.expectRevert(bytes('Contract instance has already been initialized'));

    varDebtToken.initialize(
      IPool(report.poolProxy),
      listing.underlyingAsset,
      IAaveIncentivesController(listing.incentivesController),
      decimals,
      listing.variableDebtTokenName,
      listing.variableDebtTokenSymbol,
      listing.params
    );
  }

  function test_reverts_initialize_pool_do_not_match(TestVars memory t) public {
    VariableDebtTokenInstance varDebtToken = test_new_VariableDebtToken_implementation();
    ConfiguratorInputTypes.InitReserveInput memory listing = _generateInitReserveInput(
      t,
      report,
      poolAdmin,
      true
    );

    uint8 decimals = TestnetERC20(listing.underlyingAsset).decimals();

    vm.expectRevert(bytes(Errors.POOL_ADDRESSES_DO_NOT_MATCH));

    varDebtToken.initialize(
      IPool(makeAddr('ANY_OTHER_POOL')),
      listing.underlyingAsset,
      IAaveIncentivesController(listing.incentivesController),
      decimals,
      listing.variableDebtTokenName,
      listing.variableDebtTokenSymbol,
      listing.params
    );
  }

  function test_mint_variableDebt_caller_alice(TestVars memory t) public {
    VariableDebtTokenInstance debtToken = test_initialize_VariableDebtToken(t);
    TestnetERC20 asset = TestnetERC20(debtToken.UNDERLYING_ASSET_ADDRESS());
    uint8 decimals = asset.decimals();
    uint256 amount = 1200 * 10 ** decimals;

    vm.expectEmit(address(debtToken));
    emit Mint(alice, alice, amount, 0, 1e27);

    vm.prank(report.poolProxy);
    debtToken.mint(alice, alice, amount, 1e27);

    assertEq(debtToken.scaledBalanceOf(alice), amount);
  }

  function test_mint_variableDebt_caller_bob_onBehalf_alice(TestVars memory t) public {
    VariableDebtTokenInstance debtToken = test_initialize_VariableDebtToken(t);
    TestnetERC20 asset = TestnetERC20(debtToken.UNDERLYING_ASSET_ADDRESS());
    uint8 decimals = asset.decimals();
    uint256 amount = 1200 * 10 ** decimals;

    vm.expectEmit(address(debtToken));
    emit BorrowAllowanceDelegated(alice, bob, address(asset), amount);

    vm.prank(alice);
    debtToken.approveDelegation(bob, amount);

    vm.expectEmit(address(debtToken));
    emit Mint(bob, alice, amount, 0, 1e27);

    vm.prank(report.poolProxy);
    debtToken.mint(bob, alice, amount, 1e27);

    assertEq(debtToken.scaledBalanceOf(alice), amount);
  }

  function test_partial_burn_variableDebt(TestVars memory t) public {
    VariableDebtTokenInstance debtToken = test_initialize_VariableDebtToken(t);
    TestnetERC20 asset = TestnetERC20(debtToken.UNDERLYING_ASSET_ADDRESS());
    uint8 decimals = asset.decimals();
    uint256 amount = 1200 * 10 ** decimals;
    uint256 repayment = amount / 2;
    uint256 supplyIndex = 1.001e27;
    uint256 balanceScaled = amount.rayDiv(supplyIndex);
    uint256 newIndex = 1.003e27;
    uint256 repaymentScaled = repayment.rayDiv(newIndex);

    vm.expectEmit(address(debtToken));
    emit Mint(alice, alice, amount, 0, supplyIndex);

    vm.prank(report.poolProxy);
    debtToken.mint(alice, alice, amount, supplyIndex);

    uint256 balanceIncrease = balanceScaled.rayMul(newIndex) - balanceScaled.rayMul(supplyIndex);
    vm.expectEmit(address(debtToken));
    emit Burn(alice, address(0), repayment - balanceIncrease, balanceIncrease, newIndex);

    vm.prank(report.poolProxy);
    debtToken.burn(alice, repayment, newIndex);
    assertEq(debtToken.scaledBalanceOf(alice), balanceScaled - repaymentScaled);
  }

  function test_total_burn_variableDebt(TestVars memory t) public {
    VariableDebtTokenInstance debtToken = test_initialize_VariableDebtToken(t);
    TestnetERC20 asset = TestnetERC20(debtToken.UNDERLYING_ASSET_ADDRESS());
    uint8 decimals = asset.decimals();
    uint256 amount = 1200 * 10 ** decimals;
    uint256 supplyIndex = 1.001e27;
    uint256 newIndex = 1.003e27;
    uint256 balanceScaled = amount.rayDiv(supplyIndex);
    uint256 repayment = amount;
    uint256 repaymentScaled = repayment.rayDiv(newIndex);

    vm.expectEmit(address(debtToken));
    emit Mint(alice, alice, amount, 0, supplyIndex);

    vm.prank(report.poolProxy);
    debtToken.mint(alice, alice, amount, supplyIndex);

    uint256 balanceIncrease = balanceScaled.rayMul(newIndex) - balanceScaled.rayMul(supplyIndex);
    vm.expectEmit(address(debtToken));
    emit Burn(alice, address(0), repayment - balanceIncrease, balanceIncrease, newIndex);

    vm.prank(report.poolProxy);
    debtToken.burn(alice, repayment, newIndex);
    assertEq(debtToken.scaledBalanceOf(alice), balanceScaled - repaymentScaled);
  }

  function test_reverts_operation_not_supported() public {
    VariableDebtTokenInstance varDebtToken = test_new_VariableDebtToken_implementation();

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    varDebtToken.transfer(address(0), 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    varDebtToken.allowance(address(0), address(0));

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    varDebtToken.approve(address(0), 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    varDebtToken.transferFrom(address(0), address(0), 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    varDebtToken.increaseAllowance(address(0), 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    varDebtToken.decreaseAllowance(address(0), 0);
  }

  function test_balanceOf() public {
    uint256 amount = 142e6;
    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, amount, 2, 0, alice);

    assertEq(variableDebtToken.balanceOf(alice), amount);
    uint256 previousIndex = contracts.poolProxy.getReserveNormalizedVariableDebt(tokenList.usdx);
    vm.warp(block.timestamp + 30 days);
    uint256 newIndex = contracts.poolProxy.getReserveNormalizedVariableDebt(tokenList.usdx);
    uint256 balanceIncrease = amount.rayMul(newIndex) - amount.rayMul(previousIndex);

    assertEq(variableDebtToken.balanceOf(alice), amount + balanceIncrease);
  }

  function test_totalSupply() public {
    uint256 aliceAmount = 142e6;
    uint256 bobAmount = 342e6;

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, aliceAmount, 2, 0, alice);
    vm.warp(block.timestamp + 30 days);

    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.usdx, bobAmount, 2, 0, bob);
    vm.warp(block.timestamp + 30 days);

    uint256 scaledTotalSupply = variableDebtToken.scaledTotalSupply();
    assertEq(
      variableDebtToken.totalSupply(),
      scaledTotalSupply.rayMul(contracts.poolProxy.getReserveNormalizedVariableDebt(tokenList.usdx))
    );
  }

  function test_totalScaledSupply() public {
    uint256 aliceAmount = 142e6;
    uint256 bobAmount = 342e6;

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, aliceAmount, 2, 0, alice);
    vm.warp(block.timestamp + 30 days);

    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.usdx, bobAmount, 2, 0, bob);
    vm.warp(block.timestamp + 30 days);
    uint256 totalSupply = variableDebtToken.totalSupply();
    assertEq(
      variableDebtToken.scaledTotalSupply(),
      totalSupply.rayDiv(contracts.poolProxy.getReserveNormalizedVariableDebt(tokenList.usdx))
    );
  }

  function test_scaledBalanceOf() public {
    uint256 aliceAmount1 = 142e6;
    uint256 aliceAmount2 = 342e6;
    uint256 index1 = contracts.poolProxy.getReserveNormalizedVariableDebt(tokenList.usdx);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, aliceAmount1, 2, 0, alice);
    vm.warp(block.timestamp + 30 days);

    uint256 index2 = contracts.poolProxy.getReserveNormalizedVariableDebt(tokenList.usdx);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, aliceAmount2, 2, 0, alice);
    vm.warp(block.timestamp + 30 days);

    assertEq(
      variableDebtToken.scaledBalanceOf(alice),
      aliceAmount1.rayDiv(index1) + aliceAmount2.rayDiv(index2)
    );
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
      bytes(variableDebtToken.name()),
      bytes('1'),
      address(variableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    vm.expectEmit(address(variableDebtToken));
    emit BorrowAllowanceDelegated(alice, bob, address(tokenList.usdx), amount);

    vm.prank(alice);
    variableDebtToken.delegationWithSig(alice, bob, amount, deadline, v, r, s);

    assertEq(variableDebtToken.borrowAllowance(alice, bob), amount);
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
      bytes(variableDebtToken.name()),
      bytes('1'),
      address(variableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertGt(
      variableDebtToken.borrowAllowance(alice, bob),
      0,
      'Alice borrow allowance to bob should be > 0 before cancelling the credit delegation'
    );

    vm.prank(alice);
    variableDebtToken.delegationWithSig(alice, bob, delegation.value, deadline, v, r, s);

    assertEq(
      variableDebtToken.borrowAllowance(alice, bob),
      0,
      'Alice allowance to bob should be zero'
    );
    assertEq(variableDebtToken.nonces(alice), 2, 'Alice nonce does not match expected nonce');
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
      bytes(variableDebtToken.name()),
      bytes('1'),
      address(variableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    vm.expectRevert(bytes(Errors.INVALID_SIGNATURE));

    vm.prank(alice);
    variableDebtToken.delegationWithSig(alice, bob, delegation.value, deadline, v, r, s);
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
      bytes(variableDebtToken.name()),
      bytes('1'),
      address(variableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    vm.warp(delegation.deadline + 1);
    vm.expectRevert(bytes(Errors.INVALID_EXPIRATION));

    vm.prank(alice);
    variableDebtToken.delegationWithSig(alice, bob, amount, deadline, v, r, s);
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
      bytes(variableDebtToken.name()),
      bytes('1'),
      address(variableDebtToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    vm.expectRevert(bytes(Errors.ZERO_ADDRESS_NOT_VALID));

    vm.prank(alice);
    variableDebtToken.delegationWithSig(address(0), bob, amount, deadline, v, r, s);
  }
}
