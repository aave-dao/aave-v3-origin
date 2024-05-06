// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../contracts/LibraryReportStorage.sol';
import {Create2Utils} from '../../contracts/utilities/Create2Utils.sol';

import {FlashLoanLogic} from '../../../contracts/protocol/libraries/logic/FlashLoanLogic.sol';
import {LiquidationLogic} from '../../../contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {PoolLogic} from '../../../contracts/protocol/libraries/logic/PoolLogic.sol';
import {SupplyLogic} from '../../../contracts/protocol/libraries/logic/SupplyLogic.sol';

contract AaveV3LibrariesBatch2 is LibraryReportStorage {
  constructor() {
    _librariesReport = _deployAaveV3Libraries();
  }

  function _deployAaveV3Libraries() internal returns (LibrariesReport memory libReport) {
    bytes32 salt = keccak256('AAVE_V3_LIBRARIES_BATCH');

    libReport.flashLoanLogic = Create2Utils._create2Deploy(salt, type(FlashLoanLogic).creationCode);
    libReport.liquidationLogic = Create2Utils._create2Deploy(
      salt,
      type(LiquidationLogic).creationCode
    );
    libReport.poolLogic = Create2Utils._create2Deploy(salt, type(PoolLogic).creationCode);
    libReport.supplyLogic = Create2Utils._create2Deploy(salt, type(SupplyLogic).creationCode);
    return libReport;
  }
}
