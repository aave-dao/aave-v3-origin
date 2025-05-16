// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {MockFlashLoanSimpleReceiver} from 'src/contracts/mocks/flashloan/MockSimpleFlashLoanReceiver.sol';
import {MockFlashLoanReceiver} from 'src/contracts/mocks/flashloan/MockFlashLoanReceiver.sol';
import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {IPoolAddressesProvider} from 'src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IRwaAToken} from 'src/contracts/interfaces/IRwaAToken.sol';
import {TestnetProcedures} from 'tests/utils/TestnetProcedures.sol';

contract PoolFlashLoansRwaTests is TestnetProcedures {
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

    // make BUIDL flashloanable
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFlashLoaning(tokenList.buidl, true);

    _seedLiquidity({token: tokenList.buidl, amount: 50_000e6, isRwa: true});
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
}
