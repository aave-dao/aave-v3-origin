// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {PoolLogic, ReserveLogic} from '../../../../src/contracts/protocol/libraries/logic/PoolLogic.sol';
import '../../../utils/TestnetProcedures.sol';

contract Mock {
  string public constant value = 'MOCK';
}

contract PoolLogicInitReservesTests is TestnetProcedures {
  using ReserveLogic for DataTypes.ReserveData;

  mapping(address => DataTypes.ReserveData) internal reservesData;
  mapping(uint256 => address) internal reservesList;

  function setUp() public {
    initTestEnvironment();
  }

  function test_reverts_initReserves_reserveAlreadyAdded() public {
    DataTypes.InitReserveParams memory params = DataTypes.InitReserveParams(
      address(new Mock()),
      report.aToken,
      report.variableDebtToken,
      0,
      10
    );

    assertTrue(PoolLogic.executeInitReserve(reservesData, reservesList, params));

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveAlreadyInitialized.selector));
    PoolLogic.executeInitReserve(reservesData, reservesList, params);
  }

  function test_reverts_initReserves_max() public {
    DataTypes.InitReserveParams memory params1 = DataTypes.InitReserveParams(
      address(new Mock()),
      report.aToken,
      report.variableDebtToken,
      0,
      0
    );

    vm.expectRevert(bytes(abi.encodeWithSelector(Errors.NoMoreReservesAllowed.selector)));
    PoolLogic.executeInitReserve(reservesData, reservesList, params1);
  }
}
