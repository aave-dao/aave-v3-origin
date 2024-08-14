// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../interfaces/IMarketReportTypes.sol';
import {PriceOracleSentinel, ISequencerOracle} from '../../../contracts/misc/PriceOracleSentinel.sol';
import {DefaultReserveInterestRateStrategyV2} from '../../../contracts/misc/DefaultReserveInterestRateStrategyV2.sol';
import {IErrors} from '../../interfaces/IErrors.sol';

contract AaveV3MiscProcedure is IErrors {
  function _deploySentinelAndDefaultIR(
    bool l2Flag,
    address poolAddressesProvider,
    address sequencerUptimeOracle,
    uint256 gracePeriod
  ) internal returns (MiscReport memory miscReport) {
    if (poolAddressesProvider == address(0)) revert ProviderNotFound();

    if (l2Flag && sequencerUptimeOracle != address(0) && gracePeriod != 0) {
      miscReport.priceOracleSentinel = address(
        new PriceOracleSentinel(
          IPoolAddressesProvider(poolAddressesProvider),
          ISequencerOracle(sequencerUptimeOracle),
          gracePeriod
        )
      );
    }

    miscReport.defaultInterestRateStrategy = address(
      new DefaultReserveInterestRateStrategyV2(poolAddressesProvider)
    );

    return miscReport;
  }
}
