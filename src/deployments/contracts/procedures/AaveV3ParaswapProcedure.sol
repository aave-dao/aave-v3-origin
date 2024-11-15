// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ParaSwapLiquiditySwapAdapter, IParaSwapAugustusRegistry} from '../../../contracts/extensions/paraswap-adapters/ParaSwapLiquiditySwapAdapter.sol';
import {ParaSwapRepayAdapter} from '../../../contracts/extensions/paraswap-adapters/ParaSwapRepayAdapter.sol';
import {ParaSwapWithdrawSwapAdapter} from '../../../contracts/extensions/paraswap-adapters/ParaSwapWithdrawSwapAdapter.sol';
import {IPoolAddressesProvider} from '../../../contracts/interfaces/IPoolAddressesProvider.sol';

contract AaveV3ParaswapProcedure {
  struct ParaswapAdapters {
    address paraSwapLiquiditySwapAdapter;
    address paraSwapRepayAdapter;
    address paraSwapWithdrawSwapAdapter;
  }

  function _deployAaveV3ParaswapAdapters(
    address paraswapAugustusRegistry,
    address poolAddressesProvider,
    address poolAdmin
  ) internal returns (ParaswapAdapters memory) {
    ParaswapAdapters memory report = _deployParaswapAdapters(
      paraswapAugustusRegistry,
      poolAddressesProvider,
      poolAdmin
    );

    return report;
  }

  function _deployParaswapAdapters(
    address paraswapAugustusRegistry,
    address poolAddressesProvider,
    address poolAdmin
  ) internal returns (ParaswapAdapters memory) {
    ParaswapAdapters memory report;

    if (paraswapAugustusRegistry != address(0)) {
      report.paraSwapLiquiditySwapAdapter = address(
        new ParaSwapLiquiditySwapAdapter(
          IPoolAddressesProvider(poolAddressesProvider),
          IParaSwapAugustusRegistry(paraswapAugustusRegistry),
          poolAdmin
        )
      );

      report.paraSwapRepayAdapter = address(
        new ParaSwapRepayAdapter(
          IPoolAddressesProvider(poolAddressesProvider),
          IParaSwapAugustusRegistry(paraswapAugustusRegistry),
          poolAdmin
        )
      );

      report.paraSwapWithdrawSwapAdapter = address(
        new ParaSwapWithdrawSwapAdapter(
          IPoolAddressesProvider(poolAddressesProvider),
          IParaSwapAugustusRegistry(paraswapAugustusRegistry),
          poolAdmin
        )
      );
    }
    return report;
  }
}
