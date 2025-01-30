// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3HelpersProcedureTwo} from '../../../contracts/procedures/AaveV3HelpersProcedureTwo.sol';
import '../../../interfaces/IMarketReportTypes.sol';

contract AaveV3HelpersBatchTwo is AaveV3HelpersProcedureTwo {
  StaticATokenReport internal _report;

  constructor(address pool, address rewardsController, address poolAdmin) {
    _report = _deployStaticAToken(pool, rewardsController, poolAdmin);
  }

  function staticATokenReport() external view returns (StaticATokenReport memory) {
    return _report;
  }
}
