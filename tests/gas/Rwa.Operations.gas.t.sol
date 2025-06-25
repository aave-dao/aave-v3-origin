// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {RwaATokenManager} from '../../src/contracts/misc/RwaATokenManager.sol';
import {IRwaAToken} from '../../src/contracts/interfaces/IRwaAToken.sol';
import {Testhelpers} from './Testhelpers.sol';

/**
 * Scenario suite for common RWA operations.
 */
/// forge-config: default.isolate = true
contract RwaOperations_gas_Tests is Testhelpers {
  IRwaAToken internal aBuidl;

  RwaATokenManager internal rwaATokenManager;

  function setUp() public override {
    super.setUp();
    aBuidl = IRwaAToken(rwaATokenList.aBuidl);

    vm.startPrank(poolAdmin);
    buidl.authorize(alice, true);
    buidl.mint(alice, 100e6);
    buidl.authorize(bob, true);
    vm.stopPrank();

    vm.prank(alice);
    buidl.approve(report.poolProxy, 100e6);

    rwaATokenManager = RwaATokenManager(rwaATokenTransferAdmin);
  }

  function test_authorizedTransfer() external {
    uint256 amount = 100e6;

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.buidl, amount, alice, 0);

    vm.prank(rwaATokenTransferAdmin);
    IRwaAToken(rwaATokenList.aBuidl).authorizedTransfer(alice, bob, amount);
    vm.snapshotGasLastCall('Rwa.Operations', 'authorizedTransfer: RwaAToken');
  }

  function test_transferRwaAToken() external {
    vm.prank(rwaATokenManagerOwner);
    rwaATokenManager.grantAuthorizedTransferRole(rwaATokenList.aBuidl, carol);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.buidl, 100e6, alice, 0);

    vm.prank(carol);
    rwaATokenManager.transferRwaAToken({
      aToken: rwaATokenList.aBuidl,
      from: alice,
      to: bob,
      amount: 100e6
    });
    vm.snapshotGasLastCall('Rwa.Operations', 'transferRwaAToken: RwaATokenManager');
  }

  function test_supply() external {
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.buidl, 10e6, alice, 0);
    vm.snapshotGasLastCall('Rwa.Operations', 'supply: first supply->collateralEnabled');

    _skip(100);

    contracts.poolProxy.supply(tokenList.buidl, 10e6, alice, 0);
    vm.snapshotGasLastCall('Rwa.Operations', 'supply: collateralEnabled');

    _skip(100);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.buidl, false);

    contracts.poolProxy.supply(tokenList.buidl, 10e6, alice, 0);
    vm.snapshotGasLastCall('Rwa.Operations', 'supply: collateralDisabled');
  }

  function test_withdraw() external {
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.buidl, 100e6, alice, 0);

    _skip(100);

    contracts.poolProxy.withdraw(tokenList.buidl, 50e6, alice);
    vm.snapshotGasLastCall('Rwa.Operations', 'withdraw: partial withdraw');

    _skip(100);

    contracts.poolProxy.withdraw(tokenList.buidl, type(uint256).max, alice);
    vm.snapshotGasLastCall('Rwa.Operations', 'withdraw: full withdraw');
  }
}
