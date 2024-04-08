// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from '../src/contracts/oz-common/interfaces/IERC20.sol';
import {Address} from '../src/contracts/oz-common/Address.sol';
import {ERC20} from '../src/mocks/ERC20.sol';
import {Rescuable, IRescuable} from '../src/contracts/utils/Rescuable.sol';

contract MockReceiverTokensContract is Rescuable {
  address public immutable ALLOWED;
  constructor (address allowedAddress) {
    ALLOWED = allowedAddress;
  }

  function whoCanRescue() public view override returns (address) {
    return ALLOWED;
  }
  receive() external payable {}
}

contract RescueTest is Test {
  address public constant ALLOWED = address(1023579);

  IERC20 public testToken;
  MockReceiverTokensContract public tokensReceiver;

  event ERC20Rescued(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );
  event NativeTokensRescued(address indexed caller, address indexed to, uint256 amount);

  function setUp() public {
    testToken = new ERC20('Test', 'TST');
    tokensReceiver = new MockReceiverTokensContract(ALLOWED);
  }

  function testEmergencyEtherTransfer() public {
    address randomWallet = address(1239516);
    hoax(randomWallet, 50 ether);
    Address.sendValue(payable(address(tokensReceiver)), 5 ether);

    assertEq(address(tokensReceiver).balance, 5 ether);

    address recipient = address(1230123519);

    hoax(ALLOWED);
    vm.expectEmit(true, true, false, true);
    emit NativeTokensRescued(ALLOWED, recipient, 5 ether);
    tokensReceiver.emergencyEtherTransfer(recipient, 5 ether);

    assertEq(address(tokensReceiver).balance, 0 ether);
    assertEq(address(recipient).balance, 5 ether);
  }

  function testEmergencyEtherTransferWhenNotOwner() public {
    address randomWallet = address(1239516);

    hoax(randomWallet, 50 ether);
    Address.sendValue(payable(address(tokensReceiver)), 5 ether);

    assertEq(address(tokensReceiver).balance, 5 ether);

    address recipient = address(1230123519);

    vm.expectRevert((bytes('ONLY_RESCUE_GUARDIAN')));
    tokensReceiver.emergencyEtherTransfer(recipient, 5 ether);
  }

  function testEmergencyTokenTransfer() public {
    address randomWallet = address(1239516);
    deal(address(testToken), randomWallet, 10 ether);
    hoax(randomWallet);
    testToken.transfer(address(tokensReceiver), 3 ether);

    assertEq(testToken.balanceOf(address(tokensReceiver)), 3 ether);

    address recipient = address(1230123519);

    hoax(ALLOWED);
    vm.expectEmit(true, true, false, true);
    emit ERC20Rescued(ALLOWED, address(testToken), recipient, 3 ether);
    tokensReceiver.emergencyTokenTransfer(address(testToken), recipient, 3 ether);

    assertEq(testToken.balanceOf(address(tokensReceiver)), 0);
    assertEq(testToken.balanceOf(address(recipient)), 3 ether);
  }

  function testEmergencyTokenTransferWhenNotOwner() public {
    address randomWallet = address(1239516);
    deal(address(testToken), randomWallet, 10 ether);
    hoax(randomWallet);
    testToken.transfer(address(tokensReceiver), 3 ether);

    assertEq(testToken.balanceOf(address(tokensReceiver)), 3 ether);

    address recipient = address(1230123519);

    vm.expectRevert((bytes('ONLY_RESCUE_GUARDIAN')));
    tokensReceiver.emergencyTokenTransfer(address(testToken), recipient, 3 ether);
  }
}
