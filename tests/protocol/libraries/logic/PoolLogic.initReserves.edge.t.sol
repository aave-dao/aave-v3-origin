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
      address(2),
      0,
      10
    );

    assertTrue(PoolLogic.executeInitReserve(reservesData, reservesList, params));

    vm.expectRevert(bytes(Errors.RESERVE_ALREADY_INITIALIZED));
    PoolLogic.executeInitReserve(reservesData, reservesList, params);
  }

  function test_initReserves_return_false_after_dropped_reserve() public {
    DataTypes.InitReserveParams memory params1 = DataTypes.InitReserveParams(
      address(new Mock()),
      report.aToken,
      report.variableDebtToken,
      address(2),
      0,
      10
    );

    DataTypes.InitReserveParams memory params2 = DataTypes.InitReserveParams(
      address(new Mock()),
      report.aToken,
      report.variableDebtToken,
      address(2),
      1,
      10
    );

    DataTypes.InitReserveParams memory params3 = DataTypes.InitReserveParams(
      address(new Mock()),
      report.aToken,
      report.variableDebtToken,
      address(2),
      2,
      10
    );

    assertTrue(PoolLogic.executeInitReserve(reservesData, reservesList, params1));
    assertTrue(PoolLogic.executeInitReserve(reservesData, reservesList, params2));
    assertTrue(PoolLogic.executeInitReserve(reservesData, reservesList, params3));

    PoolLogic.executeDropReserve(reservesData, reservesList, params1.asset);
    PoolLogic.executeDropReserve(reservesData, reservesList, params2.asset);

    assertFalse(PoolLogic.executeInitReserve(reservesData, reservesList, params2));
  }

  function test_reverts_initReserves_max() public {
    DataTypes.InitReserveParams memory params1 = DataTypes.InitReserveParams(
      address(new Mock()),
      report.aToken,
      report.variableDebtToken,
      address(2),
      0,
      0
    );

    vm.expectRevert(bytes(Errors.NO_MORE_RESERVES_ALLOWED));
    PoolLogic.executeInitReserve(reservesData, reservesList, params1);
  }
}
