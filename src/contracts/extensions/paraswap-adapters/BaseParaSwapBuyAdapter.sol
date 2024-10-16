// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeERC20} from '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {PercentageMath} from '../../protocol/libraries/math/PercentageMath.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IERC20Detailed} from '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IParaSwapAugustusRegistry} from './interfaces/IParaSwapAugustusRegistry.sol';
import {BaseParaSwapAdapter} from './BaseParaSwapAdapter.sol';

/**
 * @title BaseParaSwapBuyAdapter
 * @notice Implements the logic for buying tokens on ParaSwap
 */
abstract contract BaseParaSwapBuyAdapter is BaseParaSwapAdapter {
  using PercentageMath for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20Detailed;

  IParaSwapAugustusRegistry public immutable AUGUSTUS_REGISTRY;

  constructor(
    IPoolAddressesProvider addressesProvider,
    IParaSwapAugustusRegistry augustusRegistry
  ) BaseParaSwapAdapter(addressesProvider) {
    // Do something on Augustus registry to check the right contract was passed
    require(!augustusRegistry.isValidAugustus(address(0)), 'Not a valid Augustus address');
    AUGUSTUS_REGISTRY = augustusRegistry;
  }

  /**
   * @dev Swaps a token for another using ParaSwap
   * @param toAmountOffset Offset of toAmount in Augustus calldata if it should be overwritten, otherwise 0
   * @param paraswapData Data for Paraswap Adapter
   * @param assetToSwapFrom Address of the asset to be swapped from
   * @param assetToSwapTo Address of the asset to be swapped to
   * @param maxAmountToSwap Max amount to be swapped
   * @param amountToReceive Amount to be received from the swap
   * @return amountSold The amount sold during the swap
   * @return amountBought The amount bought during the swap
   */
  function _buyOnParaSwap(
    uint256 toAmountOffset,
    bytes memory paraswapData,
    IERC20Detailed assetToSwapFrom,
    IERC20Detailed assetToSwapTo,
    uint256 maxAmountToSwap,
    uint256 amountToReceive
  ) internal returns (uint256 amountSold, uint256 amountBought) {
    (bytes memory buyCalldata, address augustus) = abi.decode(paraswapData, (bytes, address));

    require(AUGUSTUS_REGISTRY.isValidAugustus(augustus), 'INVALID_AUGUSTUS');

    {
      uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
      uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

      uint256 fromAssetPrice = _getPrice(address(assetToSwapFrom));
      uint256 toAssetPrice = _getPrice(address(assetToSwapTo));

      uint256 expectedMaxAmountToSwap = amountToReceive
        .mul(toAssetPrice.mul(10 ** fromAssetDecimals))
        .div(fromAssetPrice.mul(10 ** toAssetDecimals))
        .percentMul(PercentageMath.PERCENTAGE_FACTOR.add(MAX_SLIPPAGE_PERCENT));

      require(maxAmountToSwap <= expectedMaxAmountToSwap, 'maxAmountToSwap exceed max slippage');
    }

    uint256 balanceBeforeAssetFrom = assetToSwapFrom.balanceOf(address(this));
    require(balanceBeforeAssetFrom >= maxAmountToSwap, 'INSUFFICIENT_BALANCE_BEFORE_SWAP');
    uint256 balanceBeforeAssetTo = assetToSwapTo.balanceOf(address(this));

    assetToSwapFrom.safeApprove(augustus, maxAmountToSwap);

    if (toAmountOffset != 0) {
      // Ensure 256 bit (32 bytes) toAmountOffset value is within bounds of the
      // calldata, not overlapping with the first 4 bytes (function selector).
      require(
        toAmountOffset >= 4 && toAmountOffset <= buyCalldata.length.sub(32),
        'TO_AMOUNT_OFFSET_OUT_OF_RANGE'
      );
      // Overwrite the toAmount with the correct amount for the buy.
      // In memory, buyCalldata consists of a 256 bit length field, followed by
      // the actual bytes data, that is why 32 is added to the byte offset.
      assembly {
        mstore(add(buyCalldata, add(toAmountOffset, 32)), amountToReceive)
      }
    }
    (bool success, ) = augustus.call(buyCalldata);
    if (!success) {
      // Copy revert reason from call
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Reset allowance
    assetToSwapFrom.safeApprove(augustus, 0);

    uint256 balanceAfterAssetFrom = assetToSwapFrom.balanceOf(address(this));
    amountSold = balanceBeforeAssetFrom - balanceAfterAssetFrom;
    require(amountSold <= maxAmountToSwap, 'WRONG_BALANCE_AFTER_SWAP');
    amountBought = assetToSwapTo.balanceOf(address(this)).sub(balanceBeforeAssetTo);
    require(amountBought >= amountToReceive, 'INSUFFICIENT_AMOUNT_RECEIVED');

    emit Bought(address(assetToSwapFrom), address(assetToSwapTo), amountSold, amountBought);
  }
}
