// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';

/**
 * Scenario suite for supply operations.
 */
contract PoolSupply_gas_Tests is Testhelpers {
  function test_supply() external {
    _supplyOnReserve(address(this), 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Supply', 'supply: first supply->collateralEnabled');

    _skip(100);

    _supplyOnReserve(address(this), 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Supply', 'supply: collateralEnabled');
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.usdx, false);

    _skip(100);

    _supplyOnReserve(address(this), 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Supply', 'supply: collateralDisabled');
  }
}
