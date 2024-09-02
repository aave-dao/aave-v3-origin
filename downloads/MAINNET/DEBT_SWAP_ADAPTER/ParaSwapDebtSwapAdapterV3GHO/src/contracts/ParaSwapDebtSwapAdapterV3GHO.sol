// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ParaSwapDebtSwapAdapterV3} from './ParaSwapDebtSwapAdapterV3.sol';
import {IPoolAddressesProvider} from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import {IERC20Detailed} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPool} from '@aave/core-v3/contracts/interfaces/IPool.sol';
import {DataTypes} from '@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IParaSwapAugustusRegistry} from '../interfaces/IParaSwapAugustusRegistry.sol';
import {IERC3156FlashBorrower} from '../interfaces/IERC3156FlashBorrower.sol';
import {IERC3156FlashLender} from '../interfaces/IERC3156FlashLender.sol';

// send collateral if needed via params
/**
 * @title ParaSwapDebtSwapAdapter
 * @notice ParaSwap Adapter to perform a swap of debt to another debt.
 * @author BGD labs
 **/
contract ParaSwapDebtSwapAdapterV3GHO is ParaSwapDebtSwapAdapterV3, IERC3156FlashBorrower {
  // GHO special case
  address public constant GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
  IERC3156FlashLender public constant GHO_FLASH_MINTER =
    IERC3156FlashLender(0xb639D208Bcf0589D54FaC24E655C79EC529762B8);

  constructor(
    IPoolAddressesProvider addressesProvider,
    address pool,
    IParaSwapAugustusRegistry augustusRegistry,
    address owner
  ) ParaSwapDebtSwapAdapterV3(addressesProvider, pool, augustusRegistry, owner) {
    IERC20(GHO).approve(address(GHO_FLASH_MINTER), type(uint256).max);
  }

  /// @dev ERC-3156 Flash loan callback (in this case flash mint)
  function onFlashLoan(
    address initiator,
    address token,
    uint256 amount,
    uint256 fee,
    bytes calldata data
  ) external override returns (bytes32) {
    require(msg.sender == address(GHO_FLASH_MINTER), 'SENDER_MUST_BE_MINTER');
    require(initiator == address(this), 'INITIATOR_MUST_BE_THIS');
    require(token == GHO, 'MUST_BE_GHO');
    FlashParams memory swapParams = abi.decode(data, (FlashParams));
    uint256 amountSold = _swapAndRepay(swapParams, IERC20Detailed(token), amount);

    POOL.borrow(GHO, (amountSold + fee), 2, REFERRER, swapParams.user);

    return keccak256('ERC3156FlashBorrower.onFlashLoan');
  }

  function _flash(FlashParams memory flashParams, address asset, uint256 amount) internal override {
    if (asset == GHO) {
      GHO_FLASH_MINTER.flashLoan(
        IERC3156FlashBorrower(address(this)),
        GHO,
        amount,
        abi.encode(flashParams)
      );
    } else {
      super._flash(flashParams, asset, amount);
    }
  }
}
