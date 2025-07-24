// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';
import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {IPool} from '../../../interfaces/IPool.sol';
import {IScaledBalanceToken} from '../../../interfaces/IScaledBalanceToken.sol';
import {MintableIncentivizedERC20} from './MintableIncentivizedERC20.sol';

/**
 * @title ScaledBalanceTokenBase
 * @author Aave
 * @notice Basic ERC20 implementation of scaled balance token
 */
abstract contract ScaledBalanceTokenBase is MintableIncentivizedERC20, IScaledBalanceToken {
  using WadRayMath for uint256;
  using SafeCast for uint256;

  /**
   * @dev Constructor.
   * @param pool The reference to the main Pool contract
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param decimals The number of decimals of the token
   * @param rewardsController The address of the rewards controller contract
   */
  constructor(
    IPool pool,
    string memory name,
    string memory symbol,
    uint8 decimals,
    address rewardsController
  ) MintableIncentivizedERC20(pool, name, symbol, decimals, rewardsController) {
    // Intentionally left blank
  }

  /// @inheritdoc IScaledBalanceToken
  function scaledBalanceOf(address user) external view override returns (uint256) {
    return super.balanceOf(user);
  }

  /// @inheritdoc IScaledBalanceToken
  function getScaledUserBalanceAndSupply(
    address user
  ) external view override returns (uint256, uint256) {
    return (super.balanceOf(user), super.totalSupply());
  }

  /// @inheritdoc IScaledBalanceToken
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /// @inheritdoc IScaledBalanceToken
  function getPreviousIndex(address user) external view virtual override returns (uint256) {
    return _userState[user].additionalData;
  }

  /**
   * @notice Implements the basic logic to mint a scaled balance token.
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the scaled tokens
   * @param amountScaled The amountScaled of tokens getting minted
   * @param index The next liquidity index of the reserve
   * @param getTokenBalance The function to get the balance of the token
   * @return `true` if the the previous balance of the user was 0
   */
  function _mintScaled(
    address caller,
    address onBehalfOf,
    uint256 amountScaled,
    uint256 index,
    function(uint256, uint256) internal pure returns (uint256) getTokenBalance
  ) internal returns (bool) {
    require(amountScaled != 0, Errors.InvalidMintAmount());

    uint256 scaledBalance = super.balanceOf(onBehalfOf);
    uint256 nextBalance = getTokenBalance(amountScaled + scaledBalance, index);
    uint256 previousBalance = getTokenBalance(scaledBalance, _userState[onBehalfOf].additionalData);
    uint256 balanceIncrease = getTokenBalance(scaledBalance, index) - previousBalance;

    _userState[onBehalfOf].additionalData = index.toUint128();

    _mint(onBehalfOf, amountScaled.toUint120());

    uint256 amountToMint = nextBalance - previousBalance;
    emit Transfer(address(0), onBehalfOf, amountToMint);
    emit Mint(caller, onBehalfOf, amountToMint, balanceIncrease, index);

    return (scaledBalance == 0);
  }

  /**
   * @notice Implements the basic logic to burn a scaled balance token.
   * @dev In some instances, a burn transaction will emit a mint event
   * if the amount to burn is less than the interest that the user accrued
   * @param user The user which debt is burnt
   * @param target The address that will receive the underlying, if any
   * @param amountScaled The scaled amount getting burned
   * @param index The variable debt index of the reserve
   * @param getTokenBalance The function to get the balance of the token
   * @return `true` if the the new balance of the user is 0
   */
  function _burnScaled(
    address user,
    address target,
    uint256 amountScaled,
    uint256 index,
    function(uint256, uint256) internal pure returns (uint256) getTokenBalance
  ) internal returns (bool) {
    require(amountScaled != 0, Errors.InvalidBurnAmount());

    uint256 scaledBalance = super.balanceOf(user);
    uint256 nextBalance = getTokenBalance(scaledBalance - amountScaled, index);
    uint256 previousBalance = getTokenBalance(scaledBalance, _userState[user].additionalData);
    uint256 balanceIncrease = getTokenBalance(scaledBalance, index) - previousBalance;

    _userState[user].additionalData = index.toUint128();

    _burn(user, amountScaled.toUint120());

    if (nextBalance > previousBalance) {
      uint256 amountToMint = nextBalance - previousBalance;
      emit Transfer(address(0), user, amountToMint);
      emit Mint(user, user, amountToMint, balanceIncrease, index);
    } else {
      uint256 amountToBurn = previousBalance - nextBalance;
      emit Transfer(user, address(0), amountToBurn);
      emit Burn(user, target, amountToBurn, balanceIncrease, index);
    }

    return scaledBalance - amountScaled == 0;
  }
}
