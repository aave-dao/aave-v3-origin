// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'forge-std/StdStorage.sol';

import {IPriceOracleGetter} from '../../../src/contracts/interfaces/IPriceOracleGetter.sol';
import {IERC20} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {IAccessControl} from '../../../src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {IAToken} from '../../../src/contracts/interfaces/IAToken.sol';
import {UserConfiguration} from '../../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';

contract PoolDeficitTests is TestnetProcedures {
  using stdStorage for StdStorage;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  event DeficitCovered(address indexed reserve, address caller, uint256 amountDecreased);

  function setUp() public virtual {
    initTestEnvironment(false);
  }

  function test_eliminateReserveDeficit_exactDeficit(
    address coverageAdmin,
    uint120 borrowAmount
  ) public {
    _filterAddresses(coverageAdmin);
    uint256 currentDeficit = _createReserveDeficit(borrowAmount, tokenList.usdx);

    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), coverageAdmin);

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );

    // +1 to account for imprecision on supply
    _mintATokens(tokenList.usdx, coverageAdmin, currentDeficit + 1);

    vm.startPrank(coverageAdmin);
    IERC20(tokenList.usdx).approve(report.poolProxy, UINT256_MAX);
    DataTypes.UserConfigurationMap memory userConfigBefore = contracts
      .poolProxy
      .getUserConfiguration(coverageAdmin);
    assertEq(userConfigBefore.isUsingAsCollateral(reserveData.id), true);

    // eliminate deficit
    vm.expectEmit(address(contracts.poolProxy));
    emit DeficitCovered(tokenList.usdx, coverageAdmin, currentDeficit);
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, currentDeficit);

    assertEq(contracts.poolProxy.getReserveDeficit(tokenList.usdx), 0);
  }

  function test_eliminateReserveDeficit_fullUserBalance(
    address coverageAdmin,
    uint120 borrowAmount
  ) public {
    _filterAddresses(coverageAdmin);
    uint256 currentDeficit = _createReserveDeficit(borrowAmount, tokenList.usdx);

    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), coverageAdmin);

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );

    _mintATokens(tokenList.usdx, coverageAdmin, currentDeficit / 2);

    vm.startPrank(coverageAdmin);
    IERC20(tokenList.usdx).approve(report.poolProxy, UINT256_MAX);
    DataTypes.UserConfigurationMap memory userConfigBefore = contracts
      .poolProxy
      .getUserConfiguration(coverageAdmin);
    assertEq(userConfigBefore.isUsingAsCollateral(reserveData.id), true);

    uint256 deficitToCover = IERC20(reserveData.aTokenAddress).balanceOf(coverageAdmin);
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, deficitToCover);

    DataTypes.UserConfigurationMap memory userConfigAfter = contracts
      .poolProxy
      .getUserConfiguration(coverageAdmin);
    assertEq(userConfigAfter.isUsingAsCollateral(reserveData.id), false);
  }

  function test_eliminateReserveDeficit_surplus(
    address coverageAdmin,
    uint120 borrowAmount
  ) public {
    _filterAddresses(coverageAdmin);
    uint256 currentDeficit = _createReserveDeficit(borrowAmount, tokenList.usdx);

    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), coverageAdmin);

    _mintATokens(tokenList.usdx, coverageAdmin, currentDeficit + 1000);

    // eliminate deficit
    vm.startPrank(coverageAdmin);
    IERC20(tokenList.usdx).approve(report.poolProxy, UINT256_MAX);
    vm.expectEmit(address(contracts.poolProxy));
    emit DeficitCovered(tokenList.usdx, coverageAdmin, currentDeficit);
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, currentDeficit + 1000);

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    DataTypes.UserConfigurationMap memory userConfig = contracts.poolProxy.getUserConfiguration(
      coverageAdmin
    );
    assertEq(userConfig.isUsingAsCollateral(reserveData.id), true);
  }

  function test_eliminateReserveDeficit_parcial(
    address coverageAdmin,
    uint120 borrowAmount,
    uint120 amountToCover
  ) public {
    _filterAddresses(coverageAdmin);
    uint256 currentDeficit = _createReserveDeficit(borrowAmount, tokenList.usdx);
    amountToCover = uint120(bound(amountToCover, 1, currentDeficit));

    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), coverageAdmin);

    _mintATokens(tokenList.usdx, coverageAdmin, currentDeficit);

    // eliminate deficit
    vm.startPrank(coverageAdmin);
    IERC20(tokenList.usdx).approve(report.poolProxy, UINT256_MAX);
    vm.expectEmit(address(contracts.poolProxy));
    emit DeficitCovered(tokenList.usdx, coverageAdmin, amountToCover);
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, amountToCover);
  }

  function test_reverts_eliminateReserveDeficit_has_borrows(
    address coverageAdmin,
    uint120 borrowAmount,
    uint120 cAdminBorrowAmount
  ) public {
    _filterAddresses(coverageAdmin);
    uint256 currentDeficit = _createReserveDeficit(borrowAmount, tokenList.usdx);
    cAdminBorrowAmount = uint120(bound(cAdminBorrowAmount, 1, currentDeficit / 2));

    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), coverageAdmin);

    _mintATokens(tokenList.usdx, coverageAdmin, currentDeficit);
    vm.startPrank(coverageAdmin);
    IERC20(tokenList.usdx).approve(report.poolProxy, UINT256_MAX);
    contracts.poolProxy.borrow(tokenList.usdx, cAdminBorrowAmount, 2, 0, coverageAdmin);

    vm.expectRevert(bytes(Errors.USER_CANNOT_HAVE_DEBT));
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, currentDeficit);
  }

  function test_reverts_eliminateReserveDeficit_invalid_caller(
    address caller,
    uint120 borrowAmount
  ) public {
    _filterAddresses(caller);
    uint256 currentDeficit = _createReserveDeficit(borrowAmount, tokenList.usdx);

    vm.expectRevert(bytes(Errors.CALLER_NOT_UMBRELLA));
    vm.prank(caller);
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, currentDeficit);
  }

  function test_reverts_eliminateReserveDeficit_invalid_amount(
    address coverageAdmin,
    uint120 borrowAmount
  ) public {
    _filterAddresses(coverageAdmin);

    _createReserveDeficit(borrowAmount, tokenList.usdx);

    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), coverageAdmin);

    vm.startPrank(coverageAdmin);
    vm.expectRevert(bytes(Errors.INVALID_AMOUNT));
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, 0);
  }

  function test_reverts_eliminateReserveDeficit_reserve_not_in_deficit(
    address coverageAdmin
  ) public {
    _filterAddresses(coverageAdmin);

    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), coverageAdmin);

    vm.startPrank(coverageAdmin);

    vm.expectRevert(bytes(Errors.RESERVE_NOT_IN_DEFICIT));
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, 1);
  }

  function test_interestRate() external {
    address coverageAdmin = makeAddr('covAdmin');
    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(bytes32('UMBRELLA'), coverageAdmin);
    _mintATokens(tokenList.usdx, bob, 1_000_000 ether);
    vm.prank(bob);

    contracts.poolProxy.borrow(tokenList.usdx, 200_000 ether, 2, 0, bob);
    _checkIrInvariant(tokenList.usdx);

    uint256 deficit = _createReserveDeficit(500_000 ether, tokenList.usdx, false);
    _checkIrInvariant(tokenList.usdx);

    _mintATokens(tokenList.usdx, coverageAdmin, deficit);
    vm.startPrank(coverageAdmin);
    IERC20(tokenList.usdx).approve(report.poolProxy, deficit);
    contracts.poolProxy.eliminateReserveDeficit(tokenList.usdx, deficit);
    _checkIrInvariant(tokenList.usdx);
  }

  function _checkIrInvariant(address asset) internal view {
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(asset);
    assertLt(
      reserveData.currentLiquidityRate * IERC20(reserveData.aTokenAddress).totalSupply(),
      reserveData.currentVariableBorrowRate *
        IERC20(reserveData.variableDebtTokenAddress).totalSupply()
    );
  }

  function _createReserveDeficit(
    uint256 borrowAmount,
    address borrowAsset,
    bool mintBorrowableAssets
  ) internal returns (uint256) {
    borrowAmount = bound(borrowAmount, 1e18, type(uint120).max);
    _mintATokens(tokenList.wbtc, alice, 1);

    if (mintBorrowableAssets) {
      // setup available amount to borrow
      _mintATokens(borrowAsset, carol, borrowAmount);
    }

    _borrowArbitraryAmount(borrowAsset, alice, borrowAmount);

    deal(borrowAsset, bob, borrowAmount);
    vm.prank(bob);
    IERC20(borrowAsset).approve(address(contracts.poolProxy), borrowAmount);
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(tokenList.wbtc, borrowAsset, alice, borrowAmount, false);

    uint256 currentDeficit = contracts.poolProxy.getReserveDeficit(borrowAsset);

    assertGt(currentDeficit, 0);

    return currentDeficit;
  }

  function _createReserveDeficit(
    uint120 borrowAmount,
    address borrowAsset
  ) internal returns (uint256) {
    return _createReserveDeficit(borrowAmount, borrowAsset, true);
  }

  function _filterAddresses(address user) internal view {
    vm.assume(user != address(0));
    vm.assume(user != report.poolAddressesProvider);
    vm.assume(user != alice);
    vm.assume(user != bob);
    vm.assume(user != carol);
    vm.assume(user != tokenList.usdx);
    vm.assume(user != tokenList.wbtc);
    vm.assume(user != tokenList.weth);
    vm.assume(user != 0xcF63D4456FCF098EF4012F6dbd2FA3a30f122D43);
    vm.assume(user != contracts.poolProxy.getReserveAToken(tokenList.usdx));
    vm.assume(user != contracts.poolProxy.getReserveAToken(tokenList.wbtc));
    vm.assume(user != contracts.poolProxy.getReserveAToken(tokenList.weth));
    vm.assume(user != report.poolConfiguratorProxy);
  }

  // we reinvent these helpers on each contract and should move them somewhere common
  function _mintATokens(address underlying, address receiver, uint256 amount) internal {
    deal(underlying, receiver, amount);
    vm.startPrank(receiver);
    IERC20(underlying).approve(address(contracts.poolProxy), amount);
    contracts.poolProxy.deposit(underlying, amount, receiver, 0);
    vm.stopPrank();
  }

  // assumes that the caller has at least one unit of collateralAsset that is not the borrowAsset
  function _borrowArbitraryAmount(address borrowAsset, address borrower, uint256 amount) internal {
    address oracle = contracts.poolProxy.ADDRESSES_PROVIDER().getPriceOracle();
    // set the oracle price of the borrow asset to 0
    vm.mockCall(
      oracle,
      abi.encodeWithSelector(IPriceOracleGetter.getAssetPrice.selector, address(borrowAsset)),
      abi.encode(0)
    );
    // borrow the full emount of the asset
    vm.prank(borrower);
    contracts.poolProxy.borrow(borrowAsset, amount, 2, 0, borrower);
    // revert the oracle price
    vm.clearMockedCalls();
  }
}
