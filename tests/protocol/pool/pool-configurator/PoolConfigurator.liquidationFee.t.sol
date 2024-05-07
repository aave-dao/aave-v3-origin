// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import '../../../utils/TestnetProcedures.sol';

contract PoolConfiguratorLiquidationFeeTests is TestnetProcedures {
  address internal aUSDX;

  event LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);

  function setUp() public {
    initTestEnvironment();

    (aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
  }

  function test_setLiquidationFee() public {
    uint256 previousFee = contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit LiquidationProtocolFeeChanged(tokenList.usdx, previousFee, 3000);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 3000);

    uint256 currentFee = contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);
    assertEq(currentFee, 3000);
  }

  function test_setLiquidationFee_100() public {
    uint256 previousFee = contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit LiquidationProtocolFeeChanged(tokenList.usdx, previousFee, 10000);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 10000);

    uint256 currentFee = contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);
    assertEq(currentFee, 10000);
  }

  function test_revert_setLiquidationFee_gt_100() public {
    uint256 previousFee = contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);

    vm.expectRevert(bytes(Errors.INVALID_LIQUIDATION_PROTOCOL_FEE));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 10001);

    uint256 currentFee = contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);
    assertEq(currentFee, previousFee);
  }

  function test_revert_setLiquidationFee_unauthorized() public {
    uint256 previousFee = contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(bob);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 2200);

    uint256 currentFee = contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx);
    assertEq(currentFee, previousFee);
  }
}
