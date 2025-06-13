// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Errors} from '../helpers/Errors.sol';
import {IPool} from '../../../interfaces/IPool.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

/**
 * @title IsolationModeLogic library
 * @author Aave
 * @notice Implements the base logic for handling repayments for assets borrowed in isolation mode
 */
library IsolationModeLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using SafeCast for uint256;

  /**
   * @notice increases the isolated debt whenever user borrows against isolated collateral asset
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping
   * @param reserveCache The cached data of the reserve
   * @param borrowAmount The amount being borrowed
   */
  function increaseIsolatedDebtIfIsolated(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveCache memory reserveCache,
    uint256 borrowAmount
  ) internal {
    (
      bool isolationModeActive,
      address isolationModeCollateralAddress,
      uint256 isolationModeDebtCeiling
    ) = userConfig.getIsolationModeState(reservesData, reservesList);

    if (isolationModeActive) {
      // check that the asset being borrowed is borrowable in isolation mode AND
      // the total exposure is no bigger than the collateral debt ceiling
      require(
        reserveCache.reserveConfiguration.getBorrowableInIsolation(),
        Errors.AssetNotBorrowableInIsolation()
      );

      uint128 nextIsolationModeTotalDebt = reservesData[isolationModeCollateralAddress]
        .isolationModeTotalDebt + convertToIsolatedDebtUnits(reserveCache, borrowAmount);

      require(nextIsolationModeTotalDebt <= isolationModeDebtCeiling, Errors.DebtCeilingExceeded());

      setIsolationModeTotalDebt(
        reservesData[isolationModeCollateralAddress],
        isolationModeCollateralAddress,
        nextIsolationModeTotalDebt
      );
    }
  }

  /**
   * @notice updated the isolated debt whenever a position collateralized by an isolated asset is repaid
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping
   * @param reserveCache The cached data of the reserve
   * @param repayAmount The amount being repaid
   */
  function reduceIsolatedDebtIfIsolated(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveCache memory reserveCache,
    uint256 repayAmount
  ) internal {
    (bool isolationModeActive, address isolationModeCollateralAddress, ) = userConfig
      .getIsolationModeState(reservesData, reservesList);

    if (isolationModeActive) {
      updateIsolatedDebt(reservesData, reserveCache, repayAmount, isolationModeCollateralAddress);
    }
  }

  /**
   * @notice updated the isolated debt whenever a position collateralized by an isolated asset is liquidated
   * @param reservesData The state of all the reserves
   * @param reserveCache The cached data of the reserve
   * @param repayAmount The amount being repaid
   * @param isolationModeCollateralAddress The address of the isolated collateral
   */
  function updateIsolatedDebt(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ReserveCache memory reserveCache,
    uint256 repayAmount,
    address isolationModeCollateralAddress
  ) internal {
    uint128 isolationModeTotalDebt = reservesData[isolationModeCollateralAddress]
      .isolationModeTotalDebt;

    uint128 isolatedDebtRepaid = convertToIsolatedDebtUnits(reserveCache, repayAmount);

    // since the debt ceiling does not take into account the interest accrued, it might happen that amount
    // repaid > debt in isolation mode
    uint128 newIsolationModeTotalDebt = isolationModeTotalDebt > isolatedDebtRepaid
      ? isolationModeTotalDebt - isolatedDebtRepaid
      : 0;
    setIsolationModeTotalDebt(
      reservesData[isolationModeCollateralAddress],
      isolationModeCollateralAddress,
      newIsolationModeTotalDebt
    );
  }

  /**
   * @notice Sets the isolation mode total debt of the given asset to a certain value
   * @param reserveData The state of the reserve
   * @param isolationModeCollateralAddress The address of the isolation mode collateral
   * @param newIsolationModeTotalDebt The new isolation mode total debt
   */
  function setIsolationModeTotalDebt(
    DataTypes.ReserveData storage reserveData,
    address isolationModeCollateralAddress,
    uint128 newIsolationModeTotalDebt
  ) internal {
    reserveData.isolationModeTotalDebt = newIsolationModeTotalDebt;

    emit IPool.IsolationModeTotalDebtUpdated(
      isolationModeCollateralAddress,
      newIsolationModeTotalDebt
    );
  }

  /**
   * @notice utility function to convert an amount into the isolated debt units, which usually has less decimals
   * @param reserveCache The cached data of the reserve
   * @param amount The amount being added or removed from isolated debt
   */
  function convertToIsolatedDebtUnits(
    DataTypes.ReserveCache memory reserveCache,
    uint256 amount
  ) private pure returns (uint128) {
    return
      (amount /
        10 **
          (reserveCache.reserveConfiguration.getDecimals() -
            ReserveConfiguration.DEBT_CEILING_DECIMALS)).toUint128();
  }
}
