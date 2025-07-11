// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken} from '../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';

/**
 * Scenario suite for transfer operations.
 */
/// forge-config: default.isolate = true
contract ATokenTransfer_gas_Tests is Testhelpers {
  address token;
  IAToken aToken;

  address sender = makeAddr('sender');
  address receiver = makeAddr('receiver');

  function setUp() public override {
    super.setUp();
    token = tokenList.usdx;
    address aTokenAddress = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    aToken = IAToken(aTokenAddress);
  }

  function test_transfer_fullAmount() external {
    _supplyOnReserve(sender, 1 ether);
    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'full amount; sender: ->disableCollateral; receiver: ->enableCollateral'
    );
  }

  function test_transferFrom_fullAmount() external {
    _supplyOnReserve(sender, 1 ether);
    vm.prank(sender);

    aToken.approve(receiver, 1 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'full amount; sender: ->disableCollateral; receiver: ->enableCollateral; transferFrom'
    );
  }

  function test_transfer_fullAmount_dirtyReceiver() external {
    _supplyOnReserve(receiver, 1 ether, tokenList.weth);
    _supplyOnReserve(sender, 1 ether);
    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'full amount; sender: ->disableCollateral; receiver: dirty, ->enableCollateral'
    );
  }

  function test_transferFrom_fullAmount_dirtyReceiver() external {
    _supplyOnReserve(receiver, 1 ether, tokenList.weth);
    _supplyOnReserve(sender, 1 ether);
    vm.prank(sender);

    aToken.approve(receiver, 1 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'full amount; sender: ->disableCollateral; receiver: dirty, ->enableCollateral; transferFrom'
    );
  }

  function test_transfer_fullAmount_senderCollateralDisabled() external {
    _supplyOnReserve(sender, 1 ether);
    vm.startPrank(sender);
    contracts.poolProxy.setUserUseReserveAsCollateral(token, false);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall('AToken.transfer', 'full amount; receiver: ->enableCollateral');
  }

  function test_transferFrom_fullAmount_senderCollateralDisabled() external {
    _supplyOnReserve(sender, 1 ether);
    vm.startPrank(sender);
    contracts.poolProxy.setUserUseReserveAsCollateral(token, false);

    aToken.approve(receiver, 1 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'full amount; receiver: ->enableCollateral; transferFrom'
    );
  }

  function test_transfer_fullAmount_senderCollateralDisabled_receiverNonZeroFunds2() external {
    _supplyOnReserve(sender, 1 ether);
    _supplyOnReserve(receiver, 1 ether);
    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall('AToken.transfer', 'full amount; sender: ->disableCollateral;');
  }

  function test_transferFrom_fullAmount_senderCollateralDisabled_receiverNonZeroFunds2() external {
    _supplyOnReserve(sender, 1 ether);
    _supplyOnReserve(receiver, 1 ether);
    vm.startPrank(sender);

    aToken.approve(receiver, 1 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'full amount; sender: ->disableCollateral; transferFrom'
    );
  }

  function test_transfer_fullAmount_senderCollateralDisabled_receiverNonZeroFunds() external {
    _supplyOnReserve(sender, 1 ether);
    _supplyOnReserve(receiver, 1 ether);
    vm.startPrank(sender);
    contracts.poolProxy.setUserUseReserveAsCollateral(token, false);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall('AToken.transfer', 'full amount; sender: collateralDisabled');
  }

  function test_transferFrom_fullAmount_senderCollateralDisabled_receiverNonZeroFunds() external {
    _supplyOnReserve(sender, 1 ether);
    _supplyOnReserve(receiver, 1 ether);
    vm.startPrank(sender);
    contracts.poolProxy.setUserUseReserveAsCollateral(token, false);

    aToken.approve(receiver, 1 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'full amount; sender: collateralDisabled; transferFrom'
    );
  }

  function test_transfer_partialAmount_senderCollateralEnabled() external {
    _supplyOnReserve(sender, 1 ether);
    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, 0.5 ether);
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'partial amount; sender: collateralEnabled; receiver: ->enableCollateral'
    );
  }

  function test_transferFrom_partialAmount_senderCollateralEnabled() external {
    _supplyOnReserve(sender, 1 ether);
    vm.startPrank(sender);

    aToken.approve(receiver, 0.5 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, 0.5 ether);
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'partial amount; sender: collateralEnabled; receiver: ->enableCollateral; transferFrom'
    );
  }

  function test_transfer_partialAmount_senderCollateralEnabled_receiverNonZeroFunds() external {
    _supplyOnReserve(sender, 1 ether);
    _supplyOnReserve(receiver, 1 ether);
    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, 0.5 ether);
    vm.snapshotGasLastCall('AToken.transfer', 'partial amount; sender: collateralEnabled;');
  }

  function test_transferFrom_partialAmount_senderCollateralEnabled_receiverNonZeroFunds() external {
    _supplyOnReserve(sender, 1 ether);
    _supplyOnReserve(receiver, 1 ether);
    vm.startPrank(sender);

    aToken.approve(receiver, 0.5 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, 0.5 ether);
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'partial amount; sender: collateralEnabled; transferFrom'
    );
  }

  function test_transfer_partialAmount_receiverNonZeroFunds() external {
    _supplyOnReserve(sender, 1 ether);
    _supplyOnReserve(receiver, 1 ether);
    vm.startPrank(sender);
    contracts.poolProxy.setUserUseReserveAsCollateral(token, false);

    _skip(100);

    aToken.transfer(receiver, 0.5 ether);
    vm.snapshotGasLastCall('AToken.transfer', 'partial amount; sender: collateralDisabled;');
  }

  function test_transferFrom_partialAmount_receiverNonZeroFunds() external {
    _supplyOnReserve(sender, 1 ether);
    _supplyOnReserve(receiver, 1 ether);
    vm.startPrank(sender);
    contracts.poolProxy.setUserUseReserveAsCollateral(token, false);

    aToken.approve(receiver, 0.5 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, 0.5 ether);
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'partial amount; sender: collateralDisabled; transferFrom'
    );
  }

  function test_transfer_partialAmount() external {
    _supplyOnReserve(sender, 1 ether);
    vm.startPrank(sender);
    contracts.poolProxy.setUserUseReserveAsCollateral(token, false);

    _skip(100);

    aToken.transfer(receiver, 0.5 ether);
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'partial amount; sender: collateralDisabled; receiver: ->enableCollateral'
    );
  }

  function test_transferFrom_partialAmount() external {
    _supplyOnReserve(sender, 1 ether);
    vm.startPrank(sender);
    contracts.poolProxy.setUserUseReserveAsCollateral(token, false);

    aToken.approve(receiver, 0.5 ether);

    _skip(100);

    vm.startPrank(receiver);
    aToken.transferFrom(sender, receiver, 0.5 ether);
    vm.snapshotGasLastCall(
      'AToken.transfer',
      'partial amount; sender: collateralDisabled; receiver: ->enableCollateral; transferFrom'
    );
  }

  function _supplyOnReserve(address user, uint256 amount) internal {
    _supplyOnReserve(user, amount, token);
  }
}
