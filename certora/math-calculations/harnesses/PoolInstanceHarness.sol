// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Pool} from '../munged/src/contracts/protocol/pool/Pool.sol';
import {IPoolAddressesProvider} from '../munged/src/contracts/interfaces/IPoolAddressesProvider.sol';
import {PoolInstance} from '../munged/src/contracts/instances/PoolInstance.sol';
import {IReserveInterestRateStrategy} from '../munged/src/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {DataTypes} from '../munged/src/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveLogic} from '../munged/src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {WadRayMath} from '../munged/src/contracts/protocol/libraries/math/WadRayMath.sol';
import {LiquidationLogic} from '../munged/src/contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {GenericLogic} from '../munged/src/contracts/protocol/libraries/logic/GenericLogic.sol';

contract PoolInstanceHarness is PoolInstance {
  constructor(
    IPoolAddressesProvider provider,
    IReserveInterestRateStrategy interestRateStrategy_
  ) PoolInstance(provider, interestRateStrategy_) {}

  function getNormalizedIncome(address asset) external returns (uint256) {
    return ReserveLogic.getNormalizedIncome(_reserves[asset]);
  }

  function getNormalizedDebt(address asset) external returns (uint256) {
    return ReserveLogic.getNormalizedDebt(_reserves[asset]);
  }

  function rayMul(uint256 a, uint256 b) external returns (uint256) {
    return WadRayMath.rayMul(a, b);
  }

  function rayDiv(uint256 a, uint256 b) external returns (uint256) {
    return WadRayMath.rayDiv(a, b);
  }

  function getReserveDataExtended(
    address asset
  ) external view returns (DataTypes.ReserveData memory) {
    return _reserves[asset];
  }

  function _burnBadDebt_WRP(address user) external {
    DataTypes.ExecuteLiquidationCallParams memory params;
    LiquidationLogic._burnBadDebt(_reserves, _reservesList, _usersConfig[user], params);
  }

  function WRP_calculateAvailableCollateralToLiquidate(
    DataTypes.ReserveConfigurationMap memory collateralReserveConfiguration,
    uint256 collateralAssetPrice,
    uint256 collateralAssetUnit,
    uint256 debtAssetPrice,
    uint256 debtAssetUnit,
    uint256 debtToCover,
    uint256 borrowerCollateralBalance,
    uint256 liquidationBonus
  ) external pure returns (uint256, uint256, uint256, uint256) {
    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;

    (a, b, c, d) = LiquidationLogic._calculateAvailableCollateralToLiquidate(
      collateralReserveConfiguration,
      collateralAssetPrice,
      collateralAssetUnit,
      debtAssetPrice,
      debtAssetUnit,
      debtToCover,
      borrowerCollateralBalance,
      liquidationBonus
    );
    return (a, b, c, d);
  }

  function WRP_calculateUserAccountData_ORIG(
    DataTypes.CalculateUserAccountDataParams memory params
  ) external view returns (uint256, uint256, uint256, uint256, uint256, bool) {
    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;
    uint256 e;
    bool f;
    (a, b, c, d, e, f) = GenericLogic.calculateUserAccountData(
      _reserves,
      _reservesList,
      _eModeCategories,
      params
    );

    return (a, b, c, d, e, f);
  }

  function getNextFlags(uint256 data) external pure returns (uint256, bool, bool) {
    bool isBorrowed = data & 1 == 1;
    bool isEnabledAsCollateral = data & 2 == 2;
    return (data >> 2, isBorrowed, isEnabledAsCollateral);
  }
}
