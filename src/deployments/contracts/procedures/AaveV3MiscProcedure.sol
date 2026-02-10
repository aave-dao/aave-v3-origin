// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../interfaces/IMarketReportTypes.sol';
import {DefaultReserveInterestRateStrategyV2} from '../../../contracts/misc/DefaultReserveInterestRateStrategyV2.sol';
import {IErrors} from '../../interfaces/IErrors.sol';

contract AaveV3MiscProcedure is IErrors {
  function _deployDefaultIR(
    address poolAddressesProvider
  ) internal returns (MiscReport memory miscReport) {
    if (poolAddressesProvider == address(0)) revert ProviderNotFound();

    miscReport.defaultInterestRateStrategy = address(
      new DefaultReserveInterestRateStrategyV2(poolAddressesProvider)
    );

    return miscReport;
  }
}
