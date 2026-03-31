// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract AaveProtocolDataProviderTests is TestnetProcedures {
  function setUp() public {
    initTestEnvironment(false);
  }

  function test_getSiloedBorrowing_returns_false() external view {
    assertFalse(
      contracts.protocolDataProvider.getSiloedBorrowing(tokenList.usdx),
      'getSiloedBorrowing should always return false (deprecated)'
    );
    assertFalse(
      contracts.protocolDataProvider.getSiloedBorrowing(tokenList.weth),
      'getSiloedBorrowing should always return false for any asset'
    );
  }

  function test_getDebtCeiling_returns_zero() external view {
    assertEq(
      contracts.protocolDataProvider.getDebtCeiling(tokenList.usdx),
      0,
      'getDebtCeiling should always return 0 (deprecated)'
    );
    assertEq(
      contracts.protocolDataProvider.getDebtCeiling(tokenList.weth),
      0,
      'getDebtCeiling should always return 0 for any asset'
    );
  }

  function test_getDebtCeilingDecimals_returns_zero() external view {
    assertEq(
      contracts.protocolDataProvider.getDebtCeilingDecimals(),
      0,
      'getDebtCeilingDecimals should always return 0 (deprecated)'
    );
  }

  function test_getTotalDebt() external {
    _supplyAndEnableAsCollateral(tokenList.usdx, 1_000e6, alice);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 100e6, 2, 0, alice);

    uint256 totalDebt = contracts.protocolDataProvider.getTotalDebt(tokenList.usdx);
    assertEq(totalDebt, 100e6, 'totalDebt should match borrowed amount');
  }
}
