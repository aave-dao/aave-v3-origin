// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3ParaswapProcedure} from '../../../contracts/procedures/AaveV3ParaswapProcedure.sol';
import '../../../interfaces/IMarketReportTypes.sol';

contract AaveV3ParaswapBatch is AaveV3ParaswapProcedure {
  ParaswapReport internal _report;

  constructor(
    address poolAdmin,
    MarketConfig memory config,
    address poolAddressesProvider,
    address treasury
  ) {
    ParaswapAdapters memory adaptersReport = _deployAaveV3ParaswapAdapters(
      config.paraswapAugustusRegistry,
      config.paraswapFeeClaimer,
      poolAddressesProvider,
      poolAdmin,
      treasury
    );
    _report.paraSwapLiquiditySwapAdapter = adaptersReport.paraSwapLiquiditySwapAdapter;
    _report.paraSwapRepayAdapter = adaptersReport.paraSwapRepayAdapter;
    _report.paraSwapWithdrawSwapAdapter = adaptersReport.paraSwapWithdrawSwapAdapter;
    _report.aaveParaSwapFeeClaimer = adaptersReport.aaveParaSwapFeeClaimer;
  }

  function getParaswapReport() external view returns (ParaswapReport memory) {
    return _report;
  }
}
