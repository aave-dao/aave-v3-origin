// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IPool} from '../../interfaces/IPool.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IAaveOracle} from '../../interfaces/IAaveOracle.sol';
import {IStataOracle} from './interfaces/IStataOracle.sol';
import {IERC4626} from './interfaces/IERC4626.sol';

/**
 * @title StataOracle
 * @author BGD Labs
 * @notice Contract to get asset prices of stata tokens
 */
contract StataOracle is IStataOracle {
  /// @inheritdoc IStataOracle
  IPool public immutable POOL;
  /// @inheritdoc IStataOracle
  IAaveOracle public immutable AAVE_ORACLE;

  constructor(IPoolAddressesProvider provider) {
    POOL = IPool(provider.getPool());
    AAVE_ORACLE = IAaveOracle(provider.getPriceOracle());
  }

  /// @inheritdoc IStataOracle
  function getAssetPrice(address asset) public view returns (uint256) {
    address underlying = IERC4626(asset).asset();
    return
      (AAVE_ORACLE.getAssetPrice(underlying) * POOL.getReserveNormalizedIncome(underlying)) / 1e27;
  }

  /// @inheritdoc IStataOracle
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
    uint256[] memory prices = new uint256[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      prices[i] = getAssetPrice(assets[i]);
    }
    return prices;
  }
}
