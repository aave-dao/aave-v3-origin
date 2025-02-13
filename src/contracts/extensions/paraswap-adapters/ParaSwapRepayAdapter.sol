// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {DataTypes} from '../../protocol/libraries/types/DataTypes.sol';
import {IERC20Detailed} from '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20WithPermit} from '../../interfaces/IERC20WithPermit.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {SafeERC20} from '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {BaseParaSwapBuyAdapter} from './BaseParaSwapBuyAdapter.sol';
import {IParaSwapAugustusRegistry} from './interfaces/IParaSwapAugustusRegistry.sol';
import {ReentrancyGuard} from '../../dependencies/openzeppelin/ReentrancyGuard.sol';

/**
 * @title ParaSwapRepayAdapter
 * @notice ParaSwap Adapter to perform a repay of a debt with collateral.
 * @author Aave
 **/
contract ParaSwapRepayAdapter is BaseParaSwapBuyAdapter, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct RepayParams {
    address collateralAsset;
    uint256 collateralAmount;
    uint256 rateMode;
    PermitSignature permitSignature;
    bool useEthPath;
  }

  constructor(
    IPoolAddressesProvider addressesProvider,
    IParaSwapAugustusRegistry augustusRegistry,
    address owner
  ) BaseParaSwapBuyAdapter(addressesProvider, augustusRegistry) {
    transferOwnership(owner);
  }

  /**
   * @dev Uses the received funds from the flash loan to repay a debt on the protocol on behalf of the user. Then pulls
   * the collateral from the user and swaps it to the debt asset to repay the flash loan.
   * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset, swap it
   * and repay the flash loan.
   * Supports only one asset on the flash loan.
   * @param asset The address of the flash-borrowed asset
   * @param amount The amount of the flash-borrowed asset
   * @param premium The fee of the flash-borrowed asset
   * @param initiator The address of the flashloan initiator
   * @param params The byte-encoded params passed when initiating the flashloan
   * @return True if the execution of the operation succeeds, false otherwise
   *   IERC20Detailed debtAsset Address of the debt asset
   *   uint256 debtAmount Amount of debt to be repaid
   *   uint256 rateMode Rate modes of the debt to be repaid
   *   uint256 deadline Deadline for the permit signature
   *   uint256 debtRateMode Rate mode of the debt to be repaid
   *   bytes paraswapData Paraswap Data
   *                    * bytes buyCallData Call data for augustus
   *                    * address augustus Address of Augustus Swapper
   *   PermitSignature permitParams Struct containing the permit signatures, set to all zeroes if not used
   */
  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external override nonReentrant returns (bool) {
    require(msg.sender == address(POOL), 'CALLER_MUST_BE_POOL');

    uint256 collateralAmount = amount;
    address initiatorLocal = initiator;

    IERC20Detailed collateralAsset = IERC20Detailed(asset);

    _swapAndRepay(params, premium, initiatorLocal, collateralAsset, collateralAmount);

    return true;
  }

  /**
   * @dev Swaps the user collateral for the debt asset and then repay the debt on the protocol on behalf of the user
   * without using flash loans. This method can be used when the temporary transfer of the collateral asset to this
   * contract does not affect the user position.
   * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset
   * @param collateralAsset Address of asset to be swapped
   * @param debtAsset Address of debt asset
   * @param collateralAmount max Amount of the collateral to be swapped
   * @param debtRepayAmount Amount of the debt to be repaid, or maximum amount when repaying entire debt
   * @param debtRateMode Rate mode of the debt to be repaid
   * @param buyAllBalanceOffset Set to offset of toAmount in Augustus calldata if wanting to pay entire debt, otherwise 0
   * @param paraswapData Data for Paraswap Adapter
   * @param permitSignature struct containing the permit signature
   */
  function swapAndRepay(
    IERC20Detailed collateralAsset,
    IERC20Detailed debtAsset,
    uint256 collateralAmount,
    uint256 debtRepayAmount,
    uint256 debtRateMode,
    uint256 buyAllBalanceOffset,
    bytes calldata paraswapData,
    PermitSignature calldata permitSignature
  ) external nonReentrant {
    debtRepayAmount = getDebtRepayAmount(
      debtAsset,
      debtRateMode,
      buyAllBalanceOffset,
      debtRepayAmount,
      msg.sender
    );

    // Pull aTokens from user
    _pullATokenAndWithdraw(address(collateralAsset), msg.sender, collateralAmount, permitSignature);
    //buy debt asset using collateral asset
    (uint256 amountSold, uint256 amountBought) = _buyOnParaSwap(
      buyAllBalanceOffset,
      paraswapData,
      collateralAsset,
      debtAsset,
      collateralAmount,
      debtRepayAmount
    );

    uint256 collateralBalanceLeft = collateralAmount - amountSold;

    //deposit collateral back in the pool, if left after the swap(buy)
    if (collateralBalanceLeft > 0) {
      IERC20(collateralAsset).safeApprove(address(POOL), collateralBalanceLeft);
      POOL.deposit(address(collateralAsset), collateralBalanceLeft, msg.sender, 0);
      IERC20(collateralAsset).safeApprove(address(POOL), 0);
    }

    // Repay debt. Approves 0 first to comply with tokens that implement the anti frontrunning approval fix
    IERC20(debtAsset).safeApprove(address(POOL), debtRepayAmount);
    POOL.repay(address(debtAsset), debtRepayAmount, debtRateMode, msg.sender);
    IERC20(debtAsset).safeApprove(address(POOL), 0);

    {
      //transfer excess of debtAsset back to the user, if any
      uint256 debtAssetExcess = amountBought - debtRepayAmount;
      if (debtAssetExcess > 0) {
        IERC20(debtAsset).safeTransfer(msg.sender, debtAssetExcess);
      }
    }
  }

  /**
   * @dev Perform the repay of the debt, pulls the initiator collateral and swaps to repay the flash loan
   * @param premium Fee of the flash loan
   * @param initiator Address of the user
   * @param collateralAsset Address of token to be swapped
   * @param collateralAmount Amount of the reserve to be swapped(flash loan amount)
   */

  function _swapAndRepay(
    bytes calldata params,
    uint256 premium,
    address initiator,
    IERC20Detailed collateralAsset,
    uint256 collateralAmount
  ) private {
    (
      IERC20Detailed debtAsset,
      uint256 debtRepayAmount,
      uint256 buyAllBalanceOffset,
      uint256 rateMode,
      bytes memory paraswapData,
      PermitSignature memory permitSignature
    ) = abi.decode(params, (IERC20Detailed, uint256, uint256, uint256, bytes, PermitSignature));

    debtRepayAmount = getDebtRepayAmount(
      debtAsset,
      rateMode,
      buyAllBalanceOffset,
      debtRepayAmount,
      initiator
    );

    (uint256 amountSold, uint256 amountBought) = _buyOnParaSwap(
      buyAllBalanceOffset,
      paraswapData,
      collateralAsset,
      debtAsset,
      collateralAmount,
      debtRepayAmount
    );

    // Repay debt. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    IERC20(debtAsset).safeApprove(address(POOL), debtRepayAmount);
    POOL.repay(address(debtAsset), debtRepayAmount, rateMode, initiator);
    IERC20(debtAsset).safeApprove(address(POOL), 0);

    uint256 neededForFlashLoanRepay = amountSold.add(premium);

    // Pull aTokens from user
    _pullATokenAndWithdraw(
      address(collateralAsset),
      initiator,
      neededForFlashLoanRepay,
      permitSignature
    );

    {
      //transfer excess of debtAsset back to the user, if any
      uint256 debtAssetExcess = amountBought - debtRepayAmount;
      if (debtAssetExcess > 0) {
        IERC20(debtAsset).safeTransfer(initiator, debtAssetExcess);
      }
    }

    // Repay flashloan. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    IERC20(collateralAsset).safeApprove(address(POOL), 0);
    IERC20(collateralAsset).safeApprove(address(POOL), collateralAmount.add(premium));
  }

  function getDebtRepayAmount(
    IERC20Detailed debtAsset,
    uint256 rateMode,
    uint256 buyAllBalanceOffset,
    uint256 debtRepayAmount,
    address initiator
  ) private view returns (uint256) {
    require(
      DataTypes.InterestRateMode(rateMode) == DataTypes.InterestRateMode.VARIABLE,
      'INVALID_RATE_MODE'
    );
    address variableDebtTokenAddress = POOL.getReserveVariableDebtToken(address(debtAsset));

    uint256 currentDebt = IERC20(variableDebtTokenAddress).balanceOf(initiator);

    if (buyAllBalanceOffset != 0) {
      require(currentDebt <= debtRepayAmount, 'INSUFFICIENT_AMOUNT_TO_REPAY');
      debtRepayAmount = currentDebt;
    } else {
      require(debtRepayAmount <= currentDebt, 'INVALID_DEBT_REPAY_AMOUNT');
    }

    return debtRepayAmount;
  }
}
