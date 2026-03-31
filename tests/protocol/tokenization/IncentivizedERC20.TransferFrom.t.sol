// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {MintableIncentivizedERC20} from '../../../src/contracts/protocol/tokenization/base/MintableIncentivizedERC20.sol';
import {IncentivizedERC20} from '../../../src/contracts/protocol/tokenization/base/IncentivizedERC20.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

/**
 * @dev Minimal concrete implementation of MintableIncentivizedERC20 that does NOT override
 *      transferFrom, so we can test the base IncentivizedERC20.transferFrom logic.
 */
contract MockIncentivizedERC20 is MintableIncentivizedERC20 {
  constructor(
    IPool pool,
    address rewardsController
  ) MintableIncentivizedERC20(pool, 'MockToken', 'MOCK', 18, rewardsController) {}

  function mint(address account, uint120 amount) external {
    _mint(account, amount);
  }
}

contract IncentivizedERC20TransferFromTests is TestnetProcedures {
  error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

  MockIncentivizedERC20 public token;

  function setUp() public {
    initTestEnvironment(false);
    token = new MockIncentivizedERC20(IPool(report.poolProxy), report.rewardsControllerProxy);
  }

  function test_transferFrom_withApproval() public {
    uint120 amount = 1000e18;

    token.mint(alice, amount);
    vm.prank(alice);
    token.approve(bob, amount);

    vm.prank(bob);
    // forge-lint: disable-next-line(erc20-unchecked-transfer)
    token.transferFrom(alice, carol, amount);

    assertEq(token.balanceOf(carol), amount);
    assertEq(token.balanceOf(alice), 0);
    assertEq(token.allowance(alice, bob), 0);
  }

  function test_transferFrom_partialAmount() public {
    uint120 mintAmount = 1000e18;
    uint120 transferAmount = 400e18;

    token.mint(alice, mintAmount);
    vm.prank(alice);
    token.approve(bob, mintAmount);

    vm.prank(bob);
    // forge-lint: disable-next-line(erc20-unchecked-transfer)
    token.transferFrom(alice, carol, transferAmount);

    assertEq(token.balanceOf(carol), transferAmount);
    assertEq(token.balanceOf(alice), mintAmount - transferAmount);
    assertEq(token.allowance(alice, bob), mintAmount - transferAmount);
  }

  function test_transferFrom_maxAllowanceNotConsumed() public {
    uint120 amount = 1000e18;

    token.mint(alice, amount);
    vm.prank(alice);
    token.approve(bob, type(uint256).max);

    vm.prank(bob);
    // forge-lint: disable-next-line(erc20-unchecked-transfer)
    token.transferFrom(alice, carol, amount);

    assertEq(token.balanceOf(carol), amount);
    assertEq(token.allowance(alice, bob), type(uint256).max);
  }

  function test_transferFrom_revertInsufficientAllowance() public {
    uint120 amount = 1000e18;

    token.mint(alice, amount);
    vm.prank(alice);
    token.approve(bob, amount - 1);

    vm.expectRevert(
      abi.encodeWithSelector(ERC20InsufficientAllowance.selector, bob, amount - 1, amount)
    );
    vm.prank(bob);
    // forge-lint: disable-next-line(erc20-unchecked-transfer)
    token.transferFrom(alice, carol, amount);
  }

  function test_transferFrom_revertNoAllowance() public {
    uint120 amount = 1000e18;

    token.mint(alice, amount);

    vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, bob, 0, amount));
    vm.prank(bob);
    // forge-lint: disable-next-line(erc20-unchecked-transfer)
    token.transferFrom(alice, carol, amount);
  }

  function test_transferFrom_zeroAmount() public {
    token.mint(alice, 1000e18);
    vm.prank(alice);
    token.approve(bob, 1000e18);

    vm.prank(bob);
    // forge-lint: disable-next-line(erc20-unchecked-transfer)
    token.transferFrom(alice, carol, 0);

    assertEq(token.balanceOf(carol), 0);
    assertEq(token.allowance(alice, bob), 1000e18);
  }

  function test_transferFrom_selfTransfer() public {
    uint120 amount = 500e18;

    token.mint(alice, amount);
    vm.prank(alice);
    token.approve(bob, amount);

    vm.prank(bob);
    // forge-lint: disable-next-line(erc20-unchecked-transfer)
    token.transferFrom(alice, alice, amount);

    assertEq(token.balanceOf(alice), amount);
    assertEq(token.allowance(alice, bob), 0);
  }
}
