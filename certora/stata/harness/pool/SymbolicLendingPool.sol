pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../munged/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IAToken} from '../../munged/src/contracts/interfaces/IAToken.sol';
import {DataTypes} from '../../munged/src/contracts/protocol/libraries/types/DataTypes.sol';

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

    res.configuration = reserveLegacy.configuration;
    res.liquidityIndex = reserveLegacy.liquidityIndex;
    res.currentLiquidityRate = reserveLegacy.currentLiquidityRate;
    res.variableBorrowIndex = reserveLegacy.variableBorrowIndex;
    res.currentVariableBorrowRate = reserveLegacy.currentVariableBorrowRate;
    res.currentStableBorrowRate = reserveLegacy.currentStableBorrowRate;
    res.lastUpdateTimestamp = reserveLegacy.lastUpdateTimestamp;
    res.id = reserveLegacy.id;
    res.aTokenAddress = reserveLegacy.aTokenAddress;
    res.stableDebtTokenAddress = reserveLegacy.stableDebtTokenAddress;
    res.variableDebtTokenAddress = reserveLegacy.variableDebtTokenAddress;
    res.interestRateStrategyAddress = reserveLegacy.interestRateStrategyAddress;
    res.accruedToTreasury = reserveLegacy.accruedToTreasury;
    res.unbacked = reserveLegacy.unbacked;
    res.isolationModeTotalDebt = reserveLegacy.isolationModeTotalDebt;
    return res;
  }

  function getConfiguration(
    address asset
  ) external view virtual returns (DataTypes.ReserveConfigurationMap memory) {
    return reserve.configuration;
  }

  function getVirtualUnderlyingBalance(address asset) external view virtual returns (uint128) {
    return reserve.virtualUnderlyingBalance;
  }
}
