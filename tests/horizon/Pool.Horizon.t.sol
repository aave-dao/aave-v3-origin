// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {MockFlashLoanSimpleReceiver} from '../../src/contracts/mocks/flashloan/MockSimpleFlashLoanReceiver.sol';
import {MockFlashLoanReceiver} from '../../src/contracts/mocks/flashloan/MockFlashLoanReceiver.sol';
import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IERC20} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IRwaAToken} from '../../src/contracts/interfaces/IRwaAToken.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract PoolHorizonTests is TestnetProcedures {
  MockFlashLoanReceiver internal mockFlashReceiver;
  MockFlashLoanSimpleReceiver internal mockFlashSimpleReceiver;

  function setUp() public {
    initTestEnvironment();

    mockFlashReceiver = new MockFlashLoanReceiver(
      IPoolAddressesProvider(report.poolAddressesProvider)
    );
    mockFlashSimpleReceiver = new MockFlashLoanSimpleReceiver(
      IPoolAddressesProvider(report.poolAddressesProvider)
    );

    // set buidl borrowing & flashloan config
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveBorrowing(tokenList.buidl, true);
    contracts.poolConfiguratorProxy.setReserveFlashLoaning(tokenList.buidl, true);
    vm.stopPrank();

    _seedLiquidity({token: tokenList.buidl, amount: 50_000e6, isRwa: true});
  }

  function test_fuzz_reverts_borrow_OperationNotSupported(uint256 borrowAmount) public {
    borrowAmount = bound(borrowAmount, 1, 8_000e6);

    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.wbtc, 0.4e8, bob, 0);

    vm.expectCall(
      rwaATokenList.aBuidl,
      abi.encodeCall(IRwaAToken.transferUnderlyingTo, (bob, borrowAmount))
    );

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED), rwaATokenList.aBuidl);

    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.buidl, borrowAmount, 2, 0, bob);
  }

  function test_reverts_flashLoanSimple_OperationNotSupported() public {
    uint256 amount = 2000e6;

    vm.expectCall(
      rwaATokenList.aBuidl,
      abi.encodeCall(IRwaAToken.transferUnderlyingTo, (address(mockFlashSimpleReceiver), amount))
    );

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED), rwaATokenList.aBuidl);

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple({
      receiverAddress: address(mockFlashSimpleReceiver),
      asset: tokenList.buidl,
      amount: amount,
      params: abi.encode(),
      referralCode: 0
    });
  }

  function test_fuzz_reverts_flashLoan_OperationNotSupported(uint256 amount) public {
    amount = bound(amount, 0, IERC20(rwaATokenList.aBuidl).totalSupply());

    vm.expectCall(
      rwaATokenList.aBuidl,
      abi.encodeCall(IRwaAToken.transferUnderlyingTo, (address(mockFlashReceiver), amount))
    );

    address[] memory assets = new address[](1);
    assets[0] = tokenList.buidl;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED), rwaATokenList.aBuidl);

    vm.prank(alice);
    contracts.poolProxy.flashLoan({
      receiverAddress: address(mockFlashReceiver),
      assets: assets,
      amounts: amounts,
      interestRateModes: modes,
      onBehalfOf: alice,
      params: abi.encode(),
      referralCode: 0
    });
  }

  function test_reverts_mintToTreasury_OperationNotSupported() public {
    vm.startPrank(poolAdmin);
    // set buidl borrowing config
    contracts.poolConfiguratorProxy.setReserveBorrowing(tokenList.buidl, true);
    contracts.poolConfiguratorProxy.setReserveFactor(tokenList.buidl, 10_00);
    vm.stopPrank();

    // upgrade aBuidl to the standard aToken implementation, to be able to borrow
    _upgradeToStandardAToken(tokenList.buidl, 'aBuidl');

    (, , address varDebtBuidl) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.buidl
    );

    vm.startPrank(bob);
    contracts.poolProxy.supply(tokenList.wbtc, 0.4e8, bob, 0);
    contracts.poolProxy.borrow(tokenList.buidl, 2000e6, 2, 0, bob);
    skip(30 days);
    contracts.poolProxy.repay(tokenList.buidl, IERC20(varDebtBuidl).balanceOf(bob), 2, bob);
    vm.stopPrank();

    // distribute fees to treasury
    address[] memory assets = new address[](1);
    assets[0] = tokenList.buidl;

    // upgrade aBuidl to the rwa aToken implementation, to test that mintToTreasury reverts
    _upgradeToRwaAToken(tokenList.buidl, 'aBuidl');

    // expect call by matching the selector only
    vm.expectCall(rwaATokenList.aBuidl, abi.encodeWithSelector(IRwaAToken.mintToTreasury.selector));

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
    contracts.poolProxy.mintToTreasury(assets);
  }
}
