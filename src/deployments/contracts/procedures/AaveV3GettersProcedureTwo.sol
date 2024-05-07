// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {WrappedTokenGatewayV3} from '../../../contracts/helpers/WrappedTokenGatewayV3.sol';
import {L2Encoder} from '../../../contracts/helpers/L2Encoder.sol';

contract AaveV3GettersProcedureTwo {
  struct GettersReportBatchTwo {
    address wrappedTokenGateway;
    address l2Encoder;
  }

  function _deployAaveV3GettersBatchTwo(
    address poolProxy,
    address poolAdmin,
    address wrappedNativeToken,
    bool l2Flag
  ) internal returns (GettersReportBatchTwo memory) {
    GettersReportBatchTwo memory report;

    if (wrappedNativeToken != address(0)) {
      report.wrappedTokenGateway = address(
        new WrappedTokenGatewayV3(wrappedNativeToken, poolAdmin, IPool(poolProxy))
      );
    }
    if (l2Flag) {
      report.l2Encoder = address(new L2Encoder(IPool(poolProxy)));
    }

    return report;
  }
}
