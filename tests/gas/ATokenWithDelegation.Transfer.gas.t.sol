// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {ATokenWithDelegationInstance} from '../../src/contracts/instances/ATokenWithDelegationInstance.sol';
import {ConfiguratorInputTypes} from '../../src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {IATokenWithDelegation} from '../../src/contracts/interfaces/IATokenWithDelegation.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';

import {Testhelpers, IERC20} from './Testhelpers.sol';

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

/**
 * Scenario suite for transfer operations.
 */
/// forge-config: default.isolate = true
contract ATokenWithDelegation_gas_Tests is Testhelpers {
  address token;
  IATokenWithDelegation aToken;
  address variableDebtToken;

  address sender = makeAddr('sender');
  address receiver = makeAddr('receiver');

  address user1 = makeAddr('user1');
  address user2 = makeAddr('user2');

  uint256 transferAmount;

  function setUp() public override {
    super.setUp();

    _updateATokens();

    token = tokenList.usdx;

    (address aTokenAddress, , address variableDebtTokenAddress) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.usdx);

    aToken = IATokenWithDelegation(aTokenAddress);
    variableDebtToken = variableDebtTokenAddress;

    transferAmount = 100 * 10 ** IERC20Metadata(tokenList.usdx).decimals();

    _supplyOnReserve(user1, transferAmount * 2);
    _supplyOnReserve(user2, transferAmount * 3);

    _supplyOnReserve(sender, transferAmount);
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

  function test_transfer_fullAmountWithoutDelegations_notDelegatees() external {
    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'ATokenWithDelegation.transfer',
      'full amount; sender: without delegations, not delegatee, ->disableCollateral; receiver: without delegations, not delegatee, ->enableCollateral'
    );
  }

  function test_transfer_fullAmountWithoutDelegations_delegatees() external {
    vm.prank(user1);
    aToken.delegate(sender);

    vm.prank(user2);
    aToken.delegate(receiver);

    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'ATokenWithDelegation.transfer',
      'full amount; sender: without delegations, delegatee, ->disableCollateral; receiver: without delegations, delegatee, ->enableCollateral'
    );
  }

  function test_transfer_fullAmountWithDelegations_notDelegatees() external {
    vm.prank(sender);
    aToken.delegate(user1);

    vm.prank(receiver);
    aToken.delegate(user2);

    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'ATokenWithDelegation.transfer',
      'full amount; sender: with delegations, not delegatee, ->disableCollateral; receiver: with delegations, not delegatee, ->enableCollateral'
    );
  }

  function test_transfer_fullAmountWithDelegations_delegatees() external {
    vm.prank(user1);
    aToken.delegate(sender);

    vm.prank(user2);
    aToken.delegate(receiver);

    vm.prank(sender);
    aToken.delegate(user1);

    vm.prank(receiver);
    aToken.delegate(user2);

    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'ATokenWithDelegation.transfer',
      'full amount; sender: with delegations, delegatee, ->disableCollateral; receiver: with delegations, delegatee, ->enableCollateral'
    );
  }

  function test_transfer_fullAmountSenderWithAndReceiverWithoutDelegations() external {
    vm.prank(sender);

    aToken.delegate(user1);

    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'ATokenWithDelegation.transfer',
      'full amount; sender: with delegations, ->disableCollateral; receiver: without delegations, ->enableCollateral'
    );
  }

  function test_transfer_fullAmountSenderWithoutAndReceiverWithDelegations_notDelegatees()
    external
  {
    vm.prank(receiver);

    aToken.delegate(user1);

    vm.startPrank(sender);

    _skip(100);

    aToken.transfer(receiver, aToken.balanceOf(sender));
    vm.snapshotGasLastCall(
      'ATokenWithDelegation.transfer',
      'full amount; sender: without delegations, ->disableCollateral; receiver: with delegations, ->enableCollateral'
    );
  }

  function _supplyOnReserve(address user, uint256 amount) internal {
    _supplyOnReserve(user, amount, token);
  }
}
