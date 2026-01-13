// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

// Libraries
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';
import {IDefaultInterestRateStrategyV2} from 'src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler, EnumerableSet} from '../../base/BaseHandler.t.sol';

/// @title PoolPermissionedHandler
/// @notice Handler test contract for a set of actions
contract PoolPermissionedHandler is BaseHandler {
  using EnumerableSet for EnumerableSet.UintSet;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  // Not included actions:
  // 1. dropReserve
  // 2. updateAToken
  // 3. updateVariableDebtToken

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
    contracts.poolConfiguratorProxy.setReservePause(asset, paused, uint40(gracePeriod));
    _after();

    if (!paused && gracePeriod != 0) {
      assertEq(
        snapshotGlobalVarsAfter.assetsInfo[asset].liquidationGracePeriodUntil,
        block.timestamp + gracePeriod,
        BASE_HPOST_E
      );
    }
  }

  function disableLiquidationGracePeriod(uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.disableLiquidationGracePeriod(asset);
    _after();

    assert(true);
  }

  function rescueTokens(uint256 amount, bool underlyingTokens, uint8 i) external {
    address token;
    if (underlyingTokens) {
      token = _getRandomBaseAsset(i);
    } else {
      token = _getRandomAToken(i);
    }

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
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus,
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

  function setLiquidationProtocolFee(uint16 newLiquidationProtocolFee, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(asset, newLiquidationProtocolFee);
    _after();

    assert(true);
  }

  function setPoolPause(bool paused, uint40 gracePeriod) external {
    _before();
    contracts.poolConfiguratorProxy.setPoolPause(paused, gracePeriod);
    _after();

    if (!paused && gracePeriod != 0) {
      for (uint256 i = 0; i < baseAssets.length; i++) {
        assertEq(
          snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].liquidationGracePeriodUntil,
          block.timestamp + gracePeriod,
          BASE_HPOST_E
        );
      }
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
      uint16(ltv),
      uint16(liquidationThreshold),
      uint16(liquidationBonus),
      ''
    );
    _after();

    ghost_categoryIds.add(categoryId);
  }

  function setAssetCollateralInEMode(bool allowed, uint8 i, uint8 j) external {
    address asset = _getRandomBaseAsset(i);

    uint8 categoryId = _getRandomEModeCategory(j);

    _before();
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(asset, categoryId, allowed);
    _after();

    assert(true);
  }

  function setAssetBorrowableInEMode(bool allowed, uint8 i, uint8 j) external {
    address asset = _getRandomBaseAsset(i);

    uint8 categoryId = _getRandomEModeCategory(j);

    _before();
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(asset, categoryId, allowed);
    _after();

    assert(true);
  }

  function setReserveFlashLoaning(bool flashLoanEnabled, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setReserveFlashLoaning(asset, flashLoanEnabled);
    _after();

    assert(true);
  }

  function setReserveFactor(uint16 newReserveFactor, uint8 i) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setReserveFactor(asset, newReserveFactor);
    _after();

    assert(true);
  }

  function setAssetLtvzeroInEMode(uint8 i, uint8 j, bool ltvzero) external {
    address asset = _getRandomBaseAsset(i);

    uint8 categoryId = _getRandomEModeCategory(j);

    _before();
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode({
      asset: asset,
      categoryId: categoryId,
      ltvzero: ltvzero
    });
    _after();

    assert(true);
  }

  function setReserveInterestRateData(
    IDefaultInterestRateStrategyV2.InterestRateData memory interestRateData,
    uint8 i
  ) external {
    address asset = _getRandomBaseAsset(i);

    _before();
    contracts.poolConfiguratorProxy.setReserveInterestRateData(asset, abi.encode(interestRateData));
    _after();

    assert(true);
  }

  function updateFlashloanPremium(uint16 newFlashloanPremium) external {
    _before();
    contracts.poolConfiguratorProxy.updateFlashloanPremium(uint128(newFlashloanPremium));
    _after();

    assert(true);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         EXTRA ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
