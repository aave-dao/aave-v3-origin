// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../contracts/LibraryReportStorage.sol';
import {Create2Utils} from '../../contracts/utilities/Create2Utils.sol';
import {BorrowLogic} from '../../../contracts/protocol/libraries/logic/BorrowLogic.sol';
import {ConfiguratorLogic} from '../../../contracts/protocol/libraries/logic/ConfiguratorLogic.sol';
import {EModeLogic} from '../../../contracts/protocol/libraries/logic/EModeLogic.sol';

contract AaveV3LibrariesBatch1 is LibraryReportStorage {
  constructor() {
    _librariesReport = _deployAaveV3Libraries();
  }

  function _deployAaveV3Libraries() internal returns (LibrariesReport memory libReport) {
    bytes32 salt = keccak256('AAVE_V3_LIBRARIES_BATCH');

    libReport.borrowLogic = Create2Utils._create2Deploy(salt, type(BorrowLogic).creationCode);
    libReport.configuratorLogic = Create2Utils._create2Deploy(
      salt,
      type(ConfiguratorLogic).creationCode
    );
    libReport.eModeLogic = Create2Utils._create2Deploy(salt, type(EModeLogic).creationCode);
    return libReport;
  }
}
