// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {PriceOracleSentinel} from '../../src/contracts/misc/PriceOracleSentinel.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {ACLManager} from '../../src/contracts/protocol/configuration/ACLManager.sol';
import {SequencerOracle, ISequencerOracle} from '../../src/contracts/mocks/oracle/SequencerOracle.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract PriceOracleSentinelTest is TestnetProcedures {
  address internal stranger;
  address internal riskAdmin;

  PriceOracleSentinel internal priceOracleSentinel;
  SequencerOracle internal sequencerOracleMock;

  uint256 gracePeriod = 1 days;

  event SequencerOracleUpdated(address newSequencerOracle);
  event GracePeriodUpdated(uint256 newGracePeriod);

  function setUp() public {
    initTestEnvironment();

    stranger = makeAddr('STRANGER');
    riskAdmin = makeAddr('RISK_ADMIN');

    vm.prank(roleList.marketOwner);
    ACLManager(report.aclManager).addRiskAdmin(riskAdmin);

    sequencerOracleMock = new SequencerOracle(poolAdmin);
    priceOracleSentinel = new PriceOracleSentinel(
      IPoolAddressesProvider(report.poolAddressesProvider),
      ISequencerOracle(address(sequencerOracleMock)),
      1 days
    );

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(false, 0);
  }

  function test_new_PriceOracleSentinel() public {
    address sequencerOracle = makeAddr('SEQUENCER_ORACLE');

    PriceOracleSentinel sentinel = new PriceOracleSentinel(
      IPoolAddressesProvider(report.poolAddressesProvider),
      ISequencerOracle(sequencerOracle),
      gracePeriod
    );

    assertEq(sentinel.getSequencerOracle(), sequencerOracle);
    assertEq(sentinel.getGracePeriod(), gracePeriod);
    assertEq(address(sentinel.ADDRESSES_PROVIDER()), report.poolAddressesProvider);
  }

  function test_reverts_setSequencerOracle_not_poolAdmin() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(stranger);
    priceOracleSentinel.setSequencerOracle(address(0));
  }

  function test_reverts_setGracePeriod_not_poolAdmin() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(stranger);
    priceOracleSentinel.setGracePeriod(1000 days);
  }

  function test_setSequencerOracle() public {
    vm.expectEmit(address(priceOracleSentinel));
    emit SequencerOracleUpdated(address(0));

    vm.prank(poolAdmin);
    priceOracleSentinel.setSequencerOracle(address(0));
  }

  function test_setGracePeriod() public {
    vm.expectEmit(address(priceOracleSentinel));
    emit GracePeriodUpdated(1000 days);

    vm.prank(poolAdmin);
    priceOracleSentinel.setGracePeriod(1000 days);
  }

  function test_isLiquidationAllowed_true_network_up_grace_period_pass() public {
    uint256 timestamp = block.timestamp;
    uint256 gracePeriodEnded = timestamp + 1 days + 1;

    vm.warp(gracePeriodEnded);

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(false, timestamp);

    assertEq(priceOracleSentinel.isLiquidationAllowed(), true);
  }

  function test_isLiquidationAllowed_network_up_not_grace_period() public {
    uint256 timestamp = block.timestamp;
    uint256 exactGracePeriod = timestamp + 1 days;

    vm.warp(exactGracePeriod);

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(false, timestamp);

    assertEq(priceOracleSentinel.isLiquidationAllowed(), false);
  }

  function test_isLiquidationAllowed_network_down() public {
    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(true, 0);

    assertEq(priceOracleSentinel.isLiquidationAllowed(), false);
  }

  function test_isBorrowAllowed_network_down() public {
    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(true, 0);

    assertEq(priceOracleSentinel.isBorrowAllowed(), false);
  }

  function test_isBorrowAllowed_network_up_not_grace_period() public {
    uint256 timestamp = block.timestamp;
    uint256 exactGracePeriod = timestamp + 1 days;

    vm.warp(exactGracePeriod);

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(false, timestamp);

    assertEq(priceOracleSentinel.isBorrowAllowed(), false);
  }

  function test_isBorrowAllowed_true_network_up_grace_period_pass() public {
    uint256 timestamp = block.timestamp;
    uint256 gracePeriodEnded = timestamp + 1 days + 1;

    vm.warp(gracePeriodEnded);

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(false, timestamp);

    assertEq(priceOracleSentinel.isBorrowAllowed(), true);
  }
}
