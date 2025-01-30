// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {Collector} from '../../../contracts/treasury/Collector.sol';
import '../../interfaces/IMarketReportTypes.sol';

contract AaveV3TreasuryProcedure {
  struct TreasuryReport {
    address treasuryImplementation;
    address treasury;
  }

  function _deployAaveV3Treasury(
    address poolAdmin,
    bytes32 collectorSalt
  ) internal returns (TreasuryReport memory) {
    TreasuryReport memory treasuryReport;
    bytes32 salt = collectorSalt;

    if (salt != '') {
      Collector treasuryImplementation = new Collector{salt: salt}();
      treasuryReport.treasuryImplementation = address(treasuryImplementation);

      treasuryReport.treasury = address(
        new TransparentUpgradeableProxy{salt: salt}(
          treasuryReport.treasuryImplementation,
          poolAdmin,
          abi.encodeWithSelector(treasuryImplementation.initialize.selector, 100_000, poolAdmin)
        )
      );
    } else {
      Collector treasuryImplementation = new Collector();
      treasuryReport.treasuryImplementation = address(treasuryImplementation);

      treasuryReport.treasury = address(
        new TransparentUpgradeableProxy(
          treasuryReport.treasuryImplementation,
          poolAdmin,
          abi.encodeWithSelector(treasuryImplementation.initialize.selector, 100_000, poolAdmin)
        )
      );
    }

    return treasuryReport;
  }
}
