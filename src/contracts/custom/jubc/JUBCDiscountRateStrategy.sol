// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {GhoDiscountRateStrategy} from 'gho-origin/facilitators/aave/interestStrategy/GhoDiscountRateStrategy.sol';

contract JUBCDiscountRateStrategy is GhoDiscountRateStrategy {}

// import {WadRayMath} from 'src/contracts/protocol/libraries/math/WadRayMath.sol';

// /**
//  * @title IJUBCDiscountRateStrategy
//  * @notice Interface for discount rate calculation
//  */
// interface IJUBCDiscountRateStrategy {
//   function calculateDiscountRate(uint256 debtBalance, uint256 discountTokenBalance) external view returns (uint256);
// }

// /**
//  * @title JUBCDiscountRateStrategy
//  * @author AgentBanks
//  * @notice Configurable discount rate strategy for jUBC borrowers
//  */
// contract JUBCDiscountRateStrategy is IJUBCDiscountRateStrategy {
//   using WadRayMath for uint256;

//   uint256 public immutable JUBC_DISCOUNTED_PER_DISCOUNT_TOKEN;
//   uint256 public immutable DISCOUNT_RATE;
//   uint256 public immutable MIN_DISCOUNT_TOKEN_BALANCE;
//   uint256 public immutable MIN_DEBT_TOKEN_BALANCE;

//   constructor(
//     uint256 discountedPerToken,
//     uint256 discountRate,
//     uint256 minDiscountTokenBalance,
//     uint256 minDebtTokenBalance
//   ) {
//     require(discountRate <= 10000, 'DISCOUNT_RATE_TOO_HIGH');
//     JUBC_DISCOUNTED_PER_DISCOUNT_TOKEN = discountedPerToken;
//     DISCOUNT_RATE = discountRate;
//     MIN_DISCOUNT_TOKEN_BALANCE = minDiscountTokenBalance;
//     MIN_DEBT_TOKEN_BALANCE = minDebtTokenBalance;
//   }

//   function calculateDiscountRate(uint256 debtBalance, uint256 discountTokenBalance) external view override returns (uint256) {
//     if (discountTokenBalance < MIN_DISCOUNT_TOKEN_BALANCE || debtBalance < MIN_DEBT_TOKEN_BALANCE) {
//       return 0;
//     }
//     uint256 discountedBalance = discountTokenBalance.wadMul(JUBC_DISCOUNTED_PER_DISCOUNT_TOKEN);
//     if (discountedBalance >= debtBalance) {
//       return DISCOUNT_RATE;
//     }
//     return (discountedBalance * DISCOUNT_RATE) / debtBalance;
//   }
// }
