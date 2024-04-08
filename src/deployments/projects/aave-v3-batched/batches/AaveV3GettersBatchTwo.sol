// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3GettersProcedureTwo} from '../../../contracts/procedures/AaveV3GettersProcedureTwo.sol';

contract AaveV3GettersBatchTwo is AaveV3GettersProcedureTwo {
  GettersReportBatchTwo internal _gettersReport;

  constructor(address poolProxy, address poolAdmin, address wrappedNativeToken, bool l2Flag) {
    _gettersReport = _deployAaveV3GettersBatchTwo(poolProxy, poolAdmin, wrappedNativeToken, l2Flag);
  }

  function getGettersReportTwo() external view returns (GettersReportBatchTwo memory) {
    return _gettersReport;
  }
}
