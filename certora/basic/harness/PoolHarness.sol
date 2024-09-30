// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {PoolInstance} from '../munged/contracts/instances/PoolInstance.sol';
import {DataTypes} from '../munged/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveLogic} from '../munged/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {IPoolAddressesProvider} from '../munged/contracts/interfaces/IPoolAddressesProvider.sol';

import {IERC20} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {ReserveConfiguration} from '../munged/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

contract PoolHarness is PoolInstance {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveLogic for DataTypes.ReserveCache;

  constructor(IPoolAddressesProvider provider) public PoolInstance(provider) {}

  function getCurrScaledVariableDebt(address asset) public view returns (uint256) {
    DataTypes.ReserveData storage reserve = _reserves[asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();
    return reserveCache.currScaledVariableDebt;
  }

  function getTotalDebt(address asset) public view returns (uint256) {
    uint256 totalVariable = IERC20(_reserves[asset].variableDebtTokenAddress).totalSupply();
    return totalVariable;
  }

  function getTotalATokenSupply(address asset) public view returns (uint256) {
    return IERC20(_reserves[asset].aTokenAddress).totalSupply();
  }

  function getReserveLiquidityIndex(address asset) public view returns (uint256) {
    return _reserves[asset].liquidityIndex;
  }

  function getReserveVariableBorrowIndex(address asset) public view returns (uint256) {
    return _reserves[asset].variableBorrowIndex;
  }

  function getReserveVariableBorrowRate(address asset) public view returns (uint256) {
    return _reserves[asset].currentVariableBorrowRate;
  }

  function updateReserveIndexes(address asset) public returns (bool) {
    ReserveLogic._updateIndexes(_reserves[asset], _reserves[asset].cache());
    return true;
  }

  function updateReserveIndexesWithCache(
    address asset,
    DataTypes.ReserveCache memory cache
  ) public returns (bool) {
    ReserveLogic._updateIndexes(_reserves[asset], cache);
    return true;
  }

  function cumulateToLiquidityIndex(
    address asset,
    uint256 totalLiquidity,
    uint256 amount
  ) public returns (uint256) {
    return ReserveLogic.cumulateToLiquidityIndex(_reserves[asset], totalLiquidity, amount);
  }

  function getActive(DataTypes.ReserveConfigurationMap memory self) external pure returns (bool) {
    return ReserveConfiguration.getActive(self);
  }

  function getFrozen(DataTypes.ReserveConfigurationMap memory self) external pure returns (bool) {
    return ReserveConfiguration.getFrozen(self);
  }

  function getBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self
  ) external pure returns (bool) {
    return ReserveConfiguration.getBorrowingEnabled(self);
  }
}
