// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20Detailed} from '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IERC20WithPermit} from '../../interfaces/IERC20WithPermit.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {BaseParaSwapSellAdapter} from './BaseParaSwapSellAdapter.sol';
import {IParaSwapAugustusRegistry} from './interfaces/IParaSwapAugustusRegistry.sol';
import {SafeERC20} from '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {ReentrancyGuard} from '../../dependencies/openzeppelin/ReentrancyGuard.sol';

contract ParaSwapWithdrawSwapAdapter is BaseParaSwapSellAdapter, ReentrancyGuard {
  using SafeERC20 for IERC20Detailed;

  constructor(
    IPoolAddressesProvider addressesProvider,
    IParaSwapAugustusRegistry augustusRegistry,
    address owner
  ) BaseParaSwapSellAdapter(addressesProvider, augustusRegistry) {
    transferOwnership(owner);
  }

  function executeOperation(
    address,
    uint256,
    uint256,
    address,
    bytes calldata
  ) external override nonReentrant returns (bool) {
    revert('NOT_SUPPORTED');
  }

  /**
   * @dev Swaps an amount of an asset to another after a withdraw and transfers the new asset to the user.
   * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset and perform the swap.
   * @param assetToSwapFrom Address of the underlying asset to be swapped from
   * @param assetToSwapTo Address of the underlying asset to be swapped to
   * @param amountToSwap Amount to be swapped, or maximum amount when swapping all balance
   * @param minAmountToReceive Minimum amount to be received from the swap
   * @param swapAllBalanceOffset Set to offset of fromAmount in Augustus calldata if wanting to swap all balance, otherwise 0
   * @param swapCalldata Calldata for ParaSwap's AugustusSwapper contract
   * @param augustus Address of ParaSwap's AugustusSwapper contract
   * @param permitParams Struct containing the permit signatures, set to all zeroes if not used
   */
  function withdrawAndSwap(
    IERC20Detailed assetToSwapFrom,
    IERC20Detailed assetToSwapTo,
    uint256 amountToSwap,
    uint256 minAmountToReceive,
    uint256 swapAllBalanceOffset,
    bytes calldata swapCalldata,
    address augustus,
    PermitSignature calldata permitParams
  ) external nonReentrant {
    IERC20WithPermit aToken = IERC20WithPermit(POOL.getReserveAToken(address(assetToSwapFrom)));

    if (swapAllBalanceOffset != 0) {
      uint256 balance = aToken.balanceOf(msg.sender);
      require(balance <= amountToSwap, 'INSUFFICIENT_AMOUNT_TO_SWAP');
      amountToSwap = balance;
    }

    _pullATokenAndWithdraw(
      address(assetToSwapFrom),
      aToken,
      msg.sender,
      amountToSwap,
      permitParams
    );

    uint256 amountReceived = _sellOnParaSwap(
      swapAllBalanceOffset,
      swapCalldata,
      augustus,
      assetToSwapFrom,
      assetToSwapTo,
      amountToSwap,
      minAmountToReceive
    );

    assetToSwapTo.safeTransfer(msg.sender, amountReceived);
  }
}
