// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ATokenEdgeCasesTests} from '../tokenization/ATokenEdgeCases.t.sol';

contract ATokenEdgeCasesRwaTests is ATokenEdgeCasesTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev skipping this test, approvals for not supported for RWA aTokens
  function testApprove() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this test, approvals for not supported for RWA aTokens
  function testApproveMax() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this test, approvals are not supported for RWA aTokens
  function testApproveWithZeroAddressSpender() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this test, allowances are not supported for RWA aTokens
  function testDecreaseAllowance() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this test, allowances are not supported for RWA aTokens
  function testIncreaseAllowance() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this test, allowances are not supported for RWA aTokens
  function testIncreaseAllowanceFromZero() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this test, transfers are not supported for RWA aTokens
  function testTransferFromZeroAmount() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this test, mints to treasury are not supported for RWA aTokens
  function testMintToTreasury_amount_zero() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this tests, transfers are not supported for RWA aTokens
  function test_transferFrom_zeroAddress_origin() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this test, transfers are not supported for RWA aTokens
  function test_transfer_amount_MAX_UINT_128() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }
}
