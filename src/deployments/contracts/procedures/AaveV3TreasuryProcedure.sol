// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {Collector} from '../../../contracts/treasury/Collector.sol';
import '../../interfaces/IMarketReportTypes.sol';

contract AaveV3TreasuryProcedure {
  struct TreasuryReport {
    address treasuryImplementation;
    address treasury;
  }

  function _deployAaveV3Treasury(
    address poolAdmin,
    address deployedProxyAdmin,
    bytes32 collectorSalt
  ) internal returns (TreasuryReport memory) {
    TreasuryReport memory treasuryReport;
    bytes32 salt = collectorSalt;
    address treasuryOwner = poolAdmin;
    address aclManager;

    if (salt != '') {
      Collector treasuryImplementation = new Collector{salt: salt}(aclManager);
      treasuryImplementation.initialize(0);
      treasuryReport.treasuryImplementation = address(treasuryImplementation);

      treasuryReport.treasury = address(
        new TransparentUpgradeableProxy{salt: salt}(
          treasuryReport.treasuryImplementation,
          ProxyAdmin(deployedProxyAdmin),
          abi.encodeWithSelector(treasuryImplementation.initialize.selector, 0)
        )
      );
    } else {
      Collector treasuryImplementation = new Collector(aclManager);
      treasuryImplementation.initialize(0);
      treasuryReport.treasuryImplementation = address(treasuryImplementation);

      treasuryReport.treasury = address(
        new TransparentUpgradeableProxy(
          treasuryReport.treasuryImplementation,
          ProxyAdmin(deployedProxyAdmin),
          abi.encodeWithSelector(treasuryImplementation.initialize.selector, 100_000)
        )
      );
    }

    return treasuryReport;
  }
}
