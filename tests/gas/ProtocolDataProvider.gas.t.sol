// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';

/**
 * Scenario suite for PDP getters.
 */
contract ProtocolDataProvider_gas_Tests is Testhelpers {
  // mock users to supply and borrow liquidity
  address user = makeAddr('user');

  function test_getReserveConfigurationData() external {
    contracts.protocolDataProvider.getReserveConfigurationData(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getReserveConfigurationData');
  }

  function test_getReserveCaps() external {
    contracts.protocolDataProvider.getReserveCaps(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getReserveCaps');
  }

  function test_getPaused() external {
    contracts.protocolDataProvider.getPaused(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getPaused');
  }

  function test_getSiloedBorrowing() external {
    contracts.protocolDataProvider.getSiloedBorrowing(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getSiloedBorrowing');
  }

  function test_getLiquidationProtocolFee() external {
    contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getLiquidationProtocolFee');
  }

  function test_getUnbackedMintCap() external {
    contracts.protocolDataProvider.getUnbackedMintCap(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getUnbackedMintCap');
  }

  function test_getDebtCeiling() external {
    contracts.protocolDataProvider.getDebtCeiling(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getPaused');
  }

  function test_getATokenTotalSupply() external {
    contracts.protocolDataProvider.getATokenTotalSupply(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getATokenTotalSupply');
  }

  function test_getTotalDebt() external {
    contracts.protocolDataProvider.getATokenTotalSupply(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getTotalDebt');
  }

  function test_getUserReserveData() external {
    _supplyOnReserve(user, 1e6, tokenList.usdx);

    contracts.protocolDataProvider.getUserReserveData(tokenList.usdx, user);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getUserReserveData');
  }

  function test_getReserveTokensAddresses() external {
    contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getReserveTokensAddresses');
  }

  function test_getInterestRateStrategyAddress() external {
    contracts.protocolDataProvider.getInterestRateStrategyAddress(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getInterestRateStrategyAddress');
  }

  function test_getFlashLoanEnabled() external {
    contracts.protocolDataProvider.getFlashLoanEnabled(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getFlashLoanEnabled');
  }

  function test_getIsVirtualAccActive() external {
    contracts.protocolDataProvider.getIsVirtualAccActive(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getIsVirtualAccActive');
  }

  function test_getVirtualUnderlyingBalance() external {
    contracts.protocolDataProvider.getVirtualUnderlyingBalance(tokenList.usdx);
    vm.snapshotGasLastCall('ProtocolDataProvider', 'getVirtualUnderlyingBalance');
  }
}
