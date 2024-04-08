// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IFeeClaimer} from './interfaces/IFeeClaimer.sol';
import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

/**
 * @title AaveParaSwapFeeClaimer
 * @author BGD Labs
 * @dev Helper contract that allows claiming paraswap partner fee to the collector on the respective network.
 */
contract AaveParaSwapFeeClaimer {
  // lowercase for backwards compatibility as originally this was in storage
  address public immutable aaveCollector;
  IFeeClaimer public immutable paraswapFeeClaimer;

  constructor(address _aaveCollector, IFeeClaimer _paraswapFeeClaimer) {
    require(address(_paraswapFeeClaimer) != address(0), 'PARASWAP_FEE_CLAIMER_REQUIRED');
    require(_aaveCollector != address(0), 'COLLECTOR_REQUIRED');
    aaveCollector = _aaveCollector;
    paraswapFeeClaimer = _paraswapFeeClaimer;
  }

  /**
   * @dev returns claimable balance for a specified asset
   * @param asset The asset to fetch claimable balance of
   */
  function getClaimable(address asset) public view returns (uint256) {
    return paraswapFeeClaimer.getBalance(IERC20(asset), address(this));
  }

  /**
   * @dev returns claimable balances for specified assets
   * @param assets The assets to fetch claimable balances of
   */
  function batchGetClaimable(address[] memory assets) public view returns (uint256[] memory) {
    return paraswapFeeClaimer.batchGetBalance(assets, address(this));
  }

  /**
   * @dev withdraws a single asset to the collector
   * @notice will revert when there's nothing to claim
   * @param asset The asset to claim rewards of
   */
  function claimToCollector(IERC20 asset) external {
    paraswapFeeClaimer.withdrawAllERC20(asset, aaveCollector);
  }

  /**
   * @dev withdraws all asset to the collector
   * @notice will revert when there's nothing to claim on a single supplied asset
   * @param assets The assets to claim rewards of
   */
  function batchClaimToCollector(address[] memory assets) external {
    paraswapFeeClaimer.batchWithdrawAllERC20(assets, aaveCollector);
  }
}
