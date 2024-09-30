// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.19;

import {Pool} from '../munged/contracts/protocol/pool/Pool.sol';
import {ATokenInstance} from '../munged/contracts/instances/ATokenInstance.sol';
import {WadRayMath} from '../munged/contracts/protocol/libraries/math/WadRayMath.sol';
import {ScaledBalanceTokenBase} from '../munged/contracts/protocol/tokenization/base/ScaledBalanceTokenBase.sol';
import {IScaledBalanceToken} from '../munged/contracts/interfaces/IScaledBalanceToken.sol';

/*
 * @title Certora harness for Aave ERC20 AToken
 *
 * @dev Certora's harness contract for the verification of Aave ERC20 AToken.
 */
contract ATokenHarness is ATokenInstance {
  using WadRayMath for uint256;

  constructor(Pool pool) public ATokenInstance(pool) {}

  function scaledTotalSupply()
    public
    view
    override(IScaledBalanceToken, ScaledBalanceTokenBase)
    returns (uint256)
  {
    uint256 val = super.scaledTotalSupply();
    return val;
  }

  function additionalData(address user) public view returns (uint128) {
    return _userState[user].additionalData;
  }

  function scaledBalanceOfToBalanceOf(uint256 bal) public view returns (uint256) {
    return bal.rayMul(POOL.getReserveNormalizedIncome(_underlyingAsset));
  }

  function ATokenBalanceOf(address user) public view returns (uint256) {
    return super.balanceOf(user);
  }

  function superBalance(address user) public view returns (uint256) {
    return scaledBalanceOf(user);
  }
}
