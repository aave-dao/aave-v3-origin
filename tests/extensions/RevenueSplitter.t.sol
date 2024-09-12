// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PercentageMath} from '../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {RevenueSplitter} from '../../src/contracts/treasury/RevenueSplitter.sol';
import {IRevenueSplitterErrors} from '../../src/contracts/treasury/IRevenueSplitter.sol';
import {IERC20} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import 'forge-std/StdUtils.sol';

/// @dev Simple mock of contract without fallback function
contract WalletMock {}

contract RevenueSplitterTest is StdUtils, Test {
  using PercentageMath for uint256;

  uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

  RevenueSplitter revenueSplitter;

  address recipientA;
  address recipientB;

  // add two mock tokens
  IERC20 tokenA;
  IERC20 tokenB;

  function setUp() public {
    recipientA = makeAddr('ALICE');
    recipientB = makeAddr('BOB');

    // set mock tokens
    tokenA = IERC20(address(deployMockERC20('Token A', 'TK_A', 18)));
    tokenB = IERC20(address(deployMockERC20('Token B', 'TK_B', 6)));

    revenueSplitter = new RevenueSplitter(recipientA, recipientB, 2000);
  }

  function test_constructor() public view {
    assertEq(revenueSplitter.RECIPIENT_A(), recipientA);
    assertEq(revenueSplitter.RECIPIENT_B(), recipientB);
    assertEq(revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A(), 2000);
  }

  function test_constructor_revert_invalid_split_percentage() public {
    vm.expectRevert(IRevenueSplitterErrors.InvalidPercentSplit.selector);
    new RevenueSplitter(recipientA, recipientB, 0);

    vm.expectRevert(IRevenueSplitterErrors.InvalidPercentSplit.selector);
    new RevenueSplitter(recipientA, recipientB, 100_01);

    vm.expectRevert(IRevenueSplitterErrors.InvalidPercentSplit.selector);
    new RevenueSplitter(recipientA, recipientB, 100_00);
  }

  function test_constructor_fuzzing(uint16 a) public {
    vm.assume(a > 0 && a < 100_00);
    RevenueSplitter revSplitter = new RevenueSplitter(recipientA, recipientB, a);

    assertEq(revSplitter.RECIPIENT_A(), recipientA);
    assertEq(revSplitter.RECIPIENT_B(), recipientB);
    assertEq(revSplitter.SPLIT_PERCENTAGE_RECIPIENT_A(), a);
  }

  function test_splitFunds_fuzz_max(uint256 amountA, uint256 amountB) public {
    vm.assume(
      amountA <=
        (type(uint256).max - HALF_PERCENTAGE_FACTOR) /
          revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A()
    );
    vm.assume(
      amountB <=
        (type(uint256).max - HALF_PERCENTAGE_FACTOR) /
          revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A()
    );
    _splitFunds_action(amountA, amountB);
  }

  function test_splitNativeFunds_fuzz_max(uint256 amountA) public {
    vm.assume(
      amountA <=
        (type(uint256).max - HALF_PERCENTAGE_FACTOR) /
          revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A()
    );
    _splitNativeFunds_action(amountA);
  }

  function test_splitFunds_fuzz_realistic(uint256 amountA, uint256 amountB) public {
    vm.assume(amountA < 100_000_000_000_000e18);
    vm.assume(amountB < 100_000_000_000_000e18);

    _splitFunds_action(amountA, amountB);
  }

  function test_splitFunds_fixed() public {
    _splitFunds_action(130_321_100e18, 204_0233_000e6);
  }

  function _splitFunds_action(uint256 amountA, uint256 amountB) internal {
    deal(address(tokenA), address(revenueSplitter), amountA);
    deal(address(tokenB), address(revenueSplitter), amountB);

    IERC20[] memory tokens = new IERC20[](2);
    tokens[0] = tokenA;
    tokens[1] = tokenB;

    uint256 recipientABalanceA = amountA.percentMul(revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A());
    uint256 recipientABalanceB = amountB.percentMul(revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A());

    uint256 recipientBBalanceA = amountA - recipientABalanceA;
    uint256 recipientBBalanceB = amountB - recipientABalanceB;

    revenueSplitter.splitRevenue(tokens);

    assertEq(tokenA.balanceOf(recipientA), recipientABalanceA, 'Token A balance of recipient A');
    assertEq(tokenA.balanceOf(recipientB), recipientBBalanceA, 'Token A balance of recipient B');
    assertEq(tokenB.balanceOf(recipientA), recipientABalanceB, 'Token B balance of recipient A');
    assertEq(tokenB.balanceOf(recipientB), recipientBBalanceB, 'Token B balance of recipient B');
  }

  function _splitNativeFunds_action(uint256 amountA) internal {
    address sender = makeAddr('SENDER');
    deal(sender, amountA);

    vm.prank(sender);
    payable(revenueSplitter).transfer(amountA);

    uint256 recipientABalanceA = amountA.percentMul(revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A());

    uint256 recipientBBalanceA = amountA - recipientABalanceA;

    assertEq(
      address(revenueSplitter).balance,
      amountA,
      'Splitter balance should be amount received by fallback'
    );
    assertEq(recipientA.balance, 0, 'ETH balance of recipient A');
    assertEq(recipientB.balance, 0, 'ETH balance of recipient B');

    revenueSplitter.splitNativeRevenue();

    assertEq(recipientA.balance, recipientABalanceA, 'ETH balance of recipient A');
    assertEq(recipientB.balance, recipientBBalanceA, 'ETH balance of recipient B');
    assertEq(address(revenueSplitter).balance, 0, 'Splitter balance should be zero');
  }

  function test_splitFund_zeroAmount_noOp() public {
    _splitFunds_action(0, 0);
  }

  function test_splitNativeFund_zeroAmount_noOp() public {
    _splitNativeFunds_action(0);
  }

  function test_splitFund_zeroTokens_noOp() public {
    IERC20[] memory emptyTokensList = new IERC20[](0);

    uint256 amountA = 10e18;
    uint256 amountB = 10e8;

    deal(address(tokenA), address(revenueSplitter), amountA);
    deal(address(tokenB), address(revenueSplitter), amountB);

    revenueSplitter.splitRevenue(emptyTokensList);

    assertEq(tokenA.balanceOf(recipientA), 0, 'Token A balance of recipient A');
    assertEq(tokenA.balanceOf(recipientB), 0, 'Token A balance of recipient B');
    assertEq(tokenB.balanceOf(recipientA), 0, 'Token B balance of recipient A');
    assertEq(tokenB.balanceOf(recipientB), 0, 'Token B balance of recipient B');
    assertEq(tokenA.balanceOf(address(revenueSplitter)), amountA, 'Splitter balance token A');
    assertEq(tokenB.balanceOf(address(revenueSplitter)), amountB, 'Splitter balance token B');
  }

  function test_splitFund_zeroFunds_noOp() public {
    IERC20[] memory tokenList = new IERC20[](2);
    tokenList[0] = tokenA;
    tokenList[1] = tokenB;

    revenueSplitter.splitRevenue(tokenList);

    assertEq(tokenA.balanceOf(recipientA), 0, 'Token A balance of recipient A');
    assertEq(tokenA.balanceOf(recipientB), 0, 'Token A balance of recipient B');
    assertEq(tokenB.balanceOf(recipientA), 0, 'Token B balance of recipient A');
    assertEq(tokenB.balanceOf(recipientB), 0, 'Token B balance of recipient B');
    assertEq(tokenA.balanceOf(address(revenueSplitter)), 0, 'Splitter balance token A');
    assertEq(tokenB.balanceOf(address(revenueSplitter)), 0, 'Splitter balance token B');
  }

  function test_splitFund_reverts_randomAddress() public {
    IERC20[] memory tokenList = new IERC20[](1);

    vm.expectRevert();
    revenueSplitter.splitRevenue(tokenList);

    assertEq(tokenA.balanceOf(recipientA), 0, 'Token A balance of recipient A');
    assertEq(tokenA.balanceOf(recipientB), 0, 'Token A balance of recipient B');
    assertEq(tokenB.balanceOf(recipientA), 0, 'Token B balance of recipient A');
    assertEq(tokenB.balanceOf(recipientB), 0, 'Token B balance of recipient B');
    assertEq(tokenA.balanceOf(address(revenueSplitter)), 0, 'Splitter balance token A');
    assertEq(tokenB.balanceOf(address(revenueSplitter)), 0, 'Splitter balance token B');
  }

  function test_splitNativeFund_fixedAmount() public {
    _splitNativeFunds_action(11 ether);
  }

  function test_splitFund_oneToken() public {
    uint256 amountA = 10e18;
    uint256 amountB = 10e8;

    IERC20[] memory tokenList = new IERC20[](1);
    tokenList[0] = tokenA;

    deal(address(tokenA), address(revenueSplitter), amountA);
    deal(address(tokenB), address(revenueSplitter), amountB);

    revenueSplitter.splitRevenue(tokenList);

    uint256 recipientABalanceA = amountA.percentMul(revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A());
    uint256 recipientBBalanceA = amountA - recipientABalanceA;

    assertEq(tokenA.balanceOf(recipientA), recipientABalanceA, 'Token A balance of recipient A');
    assertEq(tokenA.balanceOf(recipientB), recipientBBalanceA, 'Token A balance of recipient B');
    assertEq(tokenB.balanceOf(recipientA), 0, 'Token B balance of recipient A');
    assertEq(tokenB.balanceOf(recipientB), 0, 'Token B balance of recipient B');
    assertEq(tokenA.balanceOf(address(revenueSplitter)), 0, 'Splitter balance token A');
    assertEq(tokenB.balanceOf(address(revenueSplitter)), amountB, 'Splitter balance token B');
  }

  /// @dev Test that the contract does not revert if one of the recipients does not accept native currency, for preventing one recipient from blocking the other or for rescuing in case of an account does not support receiving native currency.
  function test_splitNativeFund_walletNotAcceptingFunds() public {
    uint256 amountA = 10 ether;
    address recipientC = address(new WalletMock());
    RevenueSplitter revenueSplitterInstance = new RevenueSplitter(recipientA, recipientC, 2000);

    deal(address(revenueSplitterInstance), amountA);

    uint256 recipientABalanceA = amountA.percentMul(
      revenueSplitterInstance.SPLIT_PERCENTAGE_RECIPIENT_A()
    );
    uint256 remaining = amountA - recipientABalanceA;

    assertEq(
      address(revenueSplitterInstance).balance,
      amountA,
      'Splitter balance should be equal to amountA'
    );
    assertEq(recipientA.balance, 0, 'ETH balance of recipient A');
    assertEq(recipientC.balance, 0, 'ETH balance of recipient C');

    revenueSplitterInstance.splitNativeRevenue();

    assertEq(recipientA.balance, recipientABalanceA, 'ETH balance of recipient A');
    assertEq(
      recipientC.balance,
      0,
      'ETH balance of recipient C should be zero due it does not contain fallback function'
    );
    assertEq(
      address(revenueSplitterInstance).balance,
      remaining,
      'Splitter balance should be the remaining'
    );
  }
}
