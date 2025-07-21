pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import {IERC20} from 'certora/atoken-with-delegation/munged/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IAToken} from 'certora/atoken-with-delegation/munged/src/contracts/interfaces/IAToken.sol';
import {WadRayMath} from 'certora/atoken-with-delegation/munged/src/contracts/protocol/libraries/math/WadRayMath.sol';

contract SymbolicLendingPoolL1 {
  using WadRayMath for uint256;

  IERC20 public underlyingToken;
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
  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
    require(asset == address(underlyingToken));
    underlyingToken.transferFrom(msg.sender, address(aToken), amount);

    uint256 scaledAmount = amount.rayDivFloor(liquidityIndex);
    aToken.mint(msg.sender, onBehalfOf, scaledAmount, liquidityIndex);
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

    uint256 scaledAmountToWithdraw = amount.rayDivCeil(liquidityIndex);
    aToken.burn(msg.sender, to, amount, scaledAmountToWithdraw, liquidityIndex);
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

  function getLiquidityIndex() external view virtual returns (uint256) {
    return liquidityIndex;
  }
}
