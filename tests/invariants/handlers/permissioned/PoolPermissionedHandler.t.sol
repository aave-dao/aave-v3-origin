// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

// Libraries

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler, EnumerableSet} from '../../base/BaseHandler.t.sol';

/// @title PoolPermissionedHandler
/// @notice Handler test contract for a set of actions
contract PoolPermissionedHandler is BaseHandler {
  using EnumerableSet for EnumerableSet.UintSet;
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  mapping(address => bool) internal ghost_reserveLtvIsZero;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external {
    _before();
    contracts.poolConfiguratorProxy.updateBridgeProtocolFee(newBridgeProtocolFee);
    _after();

    assert(true);
  }

  function setDebtCeiling(uint256 debtCeiling, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setDebtCeiling(asset, debtCeiling);
    _after();

    assert(true);
  }

  function setReservePause(bool paused, uint40 gracePeriod, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setReservePause(asset, paused, gracePeriod);
    _after();

    if (!paused && gracePeriod != 0) {
      assertReserveGracePeriodIsSet(gracePeriod, asset, BASE_HPOST_E);
    }
  }

  function disableLiquidationGracePeriod(uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.disableLiquidationGracePeriod(asset);
    _after();

    assert(true);
  }

  function rescueTokens(uint256 amount, uint8 i) external {
    address token = _getRandomBaseAsset(i);

    _before();
    pool.rescueTokens(token, address(this), amount);
    _after();

    assert(true);
  }

  function setReserveBorrowing(bool borrowing, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setReserveBorrowing(asset, borrowing);
    _after();

    assert(true);
  }

  function configureReserveAsCollateral(
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    uint8 i
  ) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      asset,
      ltv,
      liquidationThreshold,
      liquidationBonus
    );
    _after();

    ghost_reserveLtvIsZero[asset] = (ltv == 0) ? true : false;

    assert(true);
  }

  function setReserveActive(bool active, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setReserveActive(asset, active);
    _after();

    assert(true);
  }

  function setReserveFreeze(bool freeze, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setReserveFreeze(asset, freeze);
    _after();

    assert(true);
  }

  function setBorrowableInIsolation(bool borrowable, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(asset, borrowable);
    _after();

    assert(true);
  }

  function setSiloedBorrowing(bool siloed, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setSiloedBorrowing(asset, siloed);
    _after();

    assert(true);
  }

  function setBorrowCap(uint256 newBorrowCap, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setBorrowCap(asset, newBorrowCap);
    _after();

    assert(true);
  }

  function setSupplyCap(uint256 newSupplyCap, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setSupplyCap(asset, newSupplyCap);
    _after();

    assert(true);
  }

  function setLiquidationProtocolFee(uint256 newLiquidationProtocolFee, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(asset, newLiquidationProtocolFee);
    _after();

    assert(true);
  }

  function setUnbackedMintCap(uint256 newUnbackedMintCap, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setUnbackedMintCap(asset, newUnbackedMintCap);
    _after();

    assert(true);
  }

  function setPoolPause(bool paused, uint40 gracePeriod) external {
    _before();
    contracts.poolConfiguratorProxy.setPoolPause(paused, gracePeriod);
    _after();

    if (!paused && gracePeriod != 0) {
      assertReserveGracePeriodIsSetAllReserves(gracePeriod, BASE_HPOST_E);
    }
  }

  function setEModeCategory(
    uint8 categoryId,
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus
  ) external {
    _before();
    contracts.poolConfiguratorProxy.setEModeCategory(
      categoryId,
      ltv,
      liquidationThreshold,
      liquidationBonus,
      ''
    );
    _after();

    if (liquidationThreshold == 0) {
      ghost_categoryIds.remove(categoryId);
    } else {
      ghost_categoryIds.add(categoryId);
    }
  }

  function setAssetCollateralInEMode(bool allowed, uint8 i, uint8 j) external {
    address asset = _getRandomBaseAsset(i);

    uint8 categoryId = _getRandomEModeCategory(j);

    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(asset, categoryId, allowed);

    assert(true);
  }

  function setAssetBorrowableInEMode(bool allowed, uint8 i, uint8 j) external {
    address asset = _getRandomBaseAsset(i);

    uint8 categoryId = _getRandomEModeCategory(j);

    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(asset, categoryId, allowed);

    assert(true);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         EXTRA ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
