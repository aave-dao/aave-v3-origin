pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IAToken} from 'aave-v3-core/contracts/interfaces/IAToken.sol';
import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';

contract SymbolicLendingPool {
  // an underlying asset in the pool
  IERC20 public underlyingToken;
  // the aToken associated with the underlying above
  IAToken public aToken;
  // This index is used to convert the underlying token to its matching
  // AToken inside the pool, and vice versa.
  uint256 public liquidityIndex;

  /**
     * @dev Deposits underlying token in the Atoken's contract on behalf of the user,
            and mints Atoken on behalf of the user in return.
     * @param asset The underlying sent by the user and to which Atoken shall be minted
     * @param amount The amount of underlying token sent by the user
     * @param onBehalfOf The recipient of the minted Atokens
     * @param referralCode A unique code (unused)
     **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external {
    require(asset == address(underlyingToken));
    underlyingToken.transferFrom(msg.sender, address(aToken), amount);
    aToken.mint(msg.sender, onBehalfOf, amount, liquidityIndex);
  }

  /**
   * @dev Burns Atokens in exchange for underlying asset
   * @param asset The underlying asset to which the Atoken is connected
   * @param amount The amount of underlying tokens to be burned
   * @param to The recipient of the burned Atokens
   * @return The `amount` of tokens withdrawn
   **/
  function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
    require(asset == address(underlyingToken));
    aToken.burn(msg.sender, to, amount, liquidityIndex);
    return amount;
  }

  /**
   * @dev A simplification returning a constant
   * @param asset The underlying asset to which the Atoken is connected
   * @return liquidityIndex the `liquidityIndex` of the asset
   **/
  function getReserveNormalizedIncome(address asset) external view virtual returns (uint256) {
    return liquidityIndex;
  }

  DataTypes.ReserveDataLegacy reserveLegacy;
  DataTypes.ReserveData reserve;

  function getReserveData(
    address asset
  ) external view returns (DataTypes.ReserveDataLegacy memory) {
    DataTypes.ReserveDataLegacy memory res;

    res.configuration = reserve.configuration;
    res.liquidityIndex = reserve.liquidityIndex;
    res.currentLiquidityRate = reserve.currentLiquidityRate;
    res.variableBorrowIndex = reserve.variableBorrowIndex;
    res.currentVariableBorrowRate = reserve.currentVariableBorrowRate;
    res.currentStableBorrowRate = reserve.currentStableBorrowRate;
    res.lastUpdateTimestamp = reserve.lastUpdateTimestamp;
    res.id = reserve.id;
    res.aTokenAddress = reserve.aTokenAddress;
    res.stableDebtTokenAddress = reserve.stableDebtTokenAddress;
    res.variableDebtTokenAddress = reserve.variableDebtTokenAddress;
    res.interestRateStrategyAddress = reserve.interestRateStrategyAddress;
    res.accruedToTreasury = reserve.accruedToTreasury;
    res.unbacked = reserve.unbacked;
    res.isolationModeTotalDebt = reserve.isolationModeTotalDebt;
    return res;
  }

  function getReserveDataExtended(
    address asset
  ) external view returns (DataTypes.ReserveData memory) {
    return reserve;
  }
}
