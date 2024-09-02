// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {ICreditDelegationToken} from './ICreditDelegationToken.sol';
import {IERC20WithPermit} from 'solidity-utils/contracts/oz-common/interfaces/IERC20WithPermit.sol';

interface IParaswapDebtSwapAdapter {
  struct FlashParams {
    address debtAsset;
    uint256 debtRepayAmount;
    uint256 debtRateMode;
    address nestedFlashloanDebtAsset;
    uint256 nestedFlashloanDebtAmount;
    bytes paraswapData;
    uint256 offset;
    address user;
  }

  struct DebtSwapParams {
    address debtAsset;
    uint256 debtRepayAmount;
    uint256 debtRateMode;
    address newDebtAsset;
    uint256 maxNewDebtAmount;
    address extraCollateralAsset;
    uint256 extraCollateralAmount;
    uint256 offset;
    bytes paraswapData;
  }

  struct CreditDelegationInput {
    ICreditDelegationToken debtToken;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct PermitInput {
    IERC20WithPermit aToken;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @dev swaps debt from one asset to another
   * @param debtSwapParams struct describing the debt swap
   * @param creditDelegationPermit optional permit for credit delegation
   * @param collateralATokenPermit optional permit for collateral aToken
   */
  function swapDebt(
    DebtSwapParams memory debtSwapParams,
    CreditDelegationInput memory creditDelegationPermit,
    PermitInput memory collateralATokenPermit
  ) external;
}
