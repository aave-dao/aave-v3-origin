// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../interfaces/IMarketReportTypes.sol';
import {DefaultReserveInterestRateStrategyV2} from '../../../contracts/misc/DefaultReserveInterestRateStrategyV2.sol';

contract AaveV3DefaultRateStrategyProcedure {
  function _deployDefaultRateStrategyV2(address poolAddressesProvider) internal returns (address) {
    return address(new DefaultReserveInterestRateStrategyV2(poolAddressesProvider));
  }
}
