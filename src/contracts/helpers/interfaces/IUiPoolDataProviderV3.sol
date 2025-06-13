// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {DataTypes} from '../../protocol/libraries/types/DataTypes.sol';

interface IUiPoolDataProviderV3 {
  struct AggregatedReserveData {
    address underlyingAsset;
    string name;
    string symbol;
    uint256 decimals;
    uint256 baseLTVasCollateral;
    uint256 reserveLiquidationThreshold;
    uint256 reserveLiquidationBonus;
    uint256 reserveFactor;
    bool usageAsCollateralEnabled;
    bool borrowingEnabled;
    bool isActive;
    bool isFrozen;
    // base data
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 liquidityRate;
    uint128 variableBorrowRate;
    uint40 lastUpdateTimestamp;
    address aTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    //
    uint256 availableLiquidity;
    uint256 totalScaledVariableDebt;
    uint256 priceInMarketReferenceCurrency;
    address priceOracle;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
    uint256 baseVariableBorrowRate;
    uint256 optimalUsageRatio;
    // v3 only
    bool isPaused;
    bool isSiloedBorrowing;
    uint128 accruedToTreasury;
    uint128 isolationModeTotalDebt;
    bool flashLoanEnabled;
    //
    uint256 debtCeiling;
    uint256 debtCeilingDecimals;
    uint256 borrowCap;
    uint256 supplyCap;
    bool borrowableInIsolation;
    // v3.1
    uint128 virtualUnderlyingBalance;
    // v3.3
    uint128 deficit;
  }

  struct UserReserveData {
    address underlyingAsset;
    uint256 scaledATokenBalance;
    bool usageAsCollateralEnabledOnUser;
    uint256 scaledVariableDebt;
  }

  struct BaseCurrencyInfo {
    uint256 marketReferenceCurrencyUnit;
    int256 marketReferenceCurrencyPriceInUsd;
    int256 networkBaseTokenPriceInUsd;
    uint8 networkBaseTokenPriceDecimals;
  }

  struct Emode {
    uint8 id;
    DataTypes.EModeCategory eMode;
  }

  function getReservesList(
    IPoolAddressesProvider provider
  ) external view returns (address[] memory);

  function getReservesData(
    IPoolAddressesProvider provider
  ) external view returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory);

  function getUserReservesData(
    IPoolAddressesProvider provider,
    address user
  ) external view returns (UserReserveData[] memory, uint8);

  /**
   * @dev Iterates the eModes mapping and returns all eModes found
   * @notice The method assumes for id gaps <= 2 within the eMode definitions
   * @return an array of eModes that were found in the eMode mapping
   */
  function getEModes(IPoolAddressesProvider provider) external view returns (Emode[] memory);
}
