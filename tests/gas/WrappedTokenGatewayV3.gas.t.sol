// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';
import {VariableDebtToken} from '../../src/contracts/protocol/tokenization/VariableDebtToken.sol';

/**
 * Scenario suite for PDP getters.
 */
contract WrappedTokenGatewayV3_gas_Tests is Testhelpers {
  // mock users to supply and borrow liquidity
  address user = makeAddr('user');

  function test_flow() external {
    vm.startPrank(user);
    deal(user, 2 ether);
    (address aEthToken, , address wEthVariableDebt) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.weth);

    contracts.wrappedTokenGateway.depositETH{value: 1 ether}(address(0), user, 0);
    vm.snapshotGasLastCall('WrappedTokenGatewayV3', 'depositETH');

    _skip(100);

    VariableDebtToken(wEthVariableDebt).approveDelegation(
      report.wrappedTokenGateway,
      type(uint256).max
    );
    contracts.wrappedTokenGateway.borrowETH(address(0), 0.1 ether, 0);
    vm.snapshotGasLastCall('WrappedTokenGatewayV3', 'borrowETH');

    _skip(100);

    contracts.wrappedTokenGateway.repayETH{value: 0.2 ether}(address(0), type(uint256).max, user);
    vm.snapshotGasLastCall('WrappedTokenGatewayV3', 'repayETH');

    _skip(100);

    IERC20(aEthToken).approve(report.wrappedTokenGateway, type(uint256).max);
    contracts.wrappedTokenGateway.withdrawETH(address(0), type(uint256).max, user);
    vm.snapshotGasLastCall('WrappedTokenGatewayV3', 'withdrawETH');
  }
}
