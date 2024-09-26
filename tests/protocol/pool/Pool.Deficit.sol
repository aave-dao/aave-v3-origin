// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'forge-std/StdStorage.sol';

import {IERC20} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {IAccessControl} from '../../../src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

contract PoolDeficitTests is TestnetProcedures {
  using stdStorage for StdStorage;

  event BadDebtCovered(address indexed reserve, uint256 amountDecreased, uint256 currentDeficit);

  function setUp() public virtual {
    initTestEnvironment();
  }

  function test_eliminateReserveDeficit(address coverageAdmin, uint120 supplyAmount) public {
    _filterAddresses(coverageAdmin);
    (address reserveToken, uint256 currentDeficit) = _createReserveDeficit(supplyAmount);

    vm.prank(poolAdmin);
    IAccessControl(report.aclManager).grantRole('COVERAGE_ADMIN', coverageAdmin);

    deal(reserveToken, coverageAdmin, currentDeficit);

    vm.startPrank(coverageAdmin);
    IERC20(reserveToken).approve(report.poolProxy, UINT256_MAX);
    contracts.poolProxy.supply(reserveToken, currentDeficit, coverageAdmin, 0);

    // eliminate deficit
    vm.expectEmit(address(contracts.poolProxy));
    emit BadDebtCovered(reserveToken, currentDeficit, 0);
    contracts.poolProxy.eliminateReserveDeficit(reserveToken, currentDeficit);
  }

  function test_eliminateReserveDeficit_parcial(
    address coverageAdmin,
    uint120 supplyAmount,
    uint120 amountToCover
  ) public {
    _filterAddresses(coverageAdmin);
    (address reserveToken, uint256 currentDeficit) = _createReserveDeficit(supplyAmount);
    vm.assume(amountToCover != 0 && amountToCover < currentDeficit);

    vm.prank(poolAdmin);
    IAccessControl(report.aclManager).grantRole('COVERAGE_ADMIN', coverageAdmin);

    deal(reserveToken, coverageAdmin, currentDeficit);

    vm.startPrank(coverageAdmin);
    IERC20(reserveToken).approve(report.poolProxy, UINT256_MAX);
    contracts.poolProxy.supply(reserveToken, currentDeficit, coverageAdmin, 0);

    // eliminate deficit
    vm.expectEmit(address(contracts.poolProxy));
    emit BadDebtCovered(reserveToken, amountToCover, currentDeficit - amountToCover);
    contracts.poolProxy.eliminateReserveDeficit(reserveToken, amountToCover);
  }

  function test_reverts_eliminateReserveDeficit_invalid_hf(
    address coverageAdmin,
    uint120 supplyAmount,
    uint120 cAdminBorrowAmount
  ) public {
    _filterAddresses(coverageAdmin);
    (address reserveToken, uint256 currentDeficit) = _createReserveDeficit(supplyAmount);
    vm.assume(cAdminBorrowAmount != 0 && uint256(cAdminBorrowAmount) * 2 <= currentDeficit);

    vm.prank(poolAdmin);
    IAccessControl(report.aclManager).grantRole('COVERAGE_ADMIN', coverageAdmin);

    deal(reserveToken, coverageAdmin, currentDeficit);

    vm.startPrank(coverageAdmin);
    IERC20(reserveToken).approve(report.poolProxy, UINT256_MAX);
    contracts.poolProxy.supply(reserveToken, currentDeficit, coverageAdmin, 0);
    contracts.poolProxy.borrow(reserveToken, cAdminBorrowAmount, 2, 0, coverageAdmin);

    vm.expectRevert(bytes(Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD));
    contracts.poolProxy.eliminateReserveDeficit(reserveToken, currentDeficit);
  }

  function test_reverts_eliminateReserveDeficit_invalid_caller(
    address caller,
    uint120 supplyAmount
  ) public {
    _filterAddresses(caller);
    (address reserveToken, uint256 currentDeficit) = _createReserveDeficit(supplyAmount);

    vm.expectRevert(bytes(Errors.CALLER_NOT_COVERAGE_ADMIN));
    vm.prank(caller);
    contracts.poolProxy.eliminateReserveDeficit(reserveToken, currentDeficit);
  }

  function test_reverts_eliminateReserveDeficit_invalid_amount(
    address coverageAdmin,
    uint120 supplyAmount
  ) public {
    _filterAddresses(coverageAdmin);

    (address reserveToken, ) = _createReserveDeficit(supplyAmount);

    vm.prank(poolAdmin);
    IAccessControl(report.aclManager).grantRole('COVERAGE_ADMIN', coverageAdmin);

    vm.startPrank(coverageAdmin);
    vm.expectRevert(bytes(Errors.INVALID_AMOUNT));
    contracts.poolProxy.eliminateReserveDeficit(reserveToken, 0);
  }

  function test_reverts_eliminateReserveDeficit_reserve_not_in_deficit(
    address coverageAdmin,
    uint120 supplyAmount
  ) public {
    _filterAddresses(coverageAdmin);

    vm.prank(poolAdmin);
    IAccessControl(report.aclManager).grantRole('COVERAGE_ADMIN', coverageAdmin);

    vm.startPrank(coverageAdmin);

    vm.expectRevert(bytes(Errors.RESERVE_NOT_IN_DEFICIT));
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, 1);
  }

  function _createReserveDeficit(uint120 supplyAmount) internal returns (address, uint256) {
    vm.assume(supplyAmount != 0);
    deal(tokenList.wbtc, alice, supplyAmount);
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, alice, 0);
    (, , uint256 availableBorrowsBase, , , ) = contracts.poolProxy.getUserAccountData(alice);

    uint256 borrowAmount = availableBorrowsBase / 1e2; // base unit -> usdx unit

    // setup available amount to borrow
    deal(tokenList.usdx, carol, borrowAmount);
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, borrowAmount, carol, 0);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    vm.warp(block.timestamp + 30 days);

    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.wbtc))
      .sig('_latestAnswer()')
      .checked_write(
        _calcPrice(IAaveOracle(report.aaveOracle).getAssetPrice(tokenList.wbtc), 20_00)
      );

    deal(tokenList.usdx, bob, borrowAmount);
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(tokenList.wbtc, tokenList.usdx, alice, borrowAmount, false);

    uint256 currentDeficit = contracts.poolProxy.getReserveDeficit(tokenList.usdx);

    assertGt(currentDeficit, 0);

    return (tokenList.usdx, currentDeficit);
  }

  function _filterAddresses(address user) internal {
    vm.assume(user != address(0));
    vm.assume(user != report.proxyAdmin);
    vm.assume(user != report.poolAddressesProvider);
    vm.assume(user != alice);
    vm.assume(user != bob);
    vm.assume(user != carol);
    vm.assume(user != tokenList.usdx);
    vm.assume(user != tokenList.wbtc);
    vm.assume(user != tokenList.weth);
    vm.assume(user != 0xcF63D4456FCF098EF4012F6dbd2FA3a30f122D43);
  }
}
