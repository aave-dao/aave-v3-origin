// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';

// Libraries

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title PoolHandler
/// @notice Handler test contract for a set of actions
contract PoolHandler is BaseHandler {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function mintToTreasury(uint8 i) external setup {
    bool success;
    bytes memory returnData;

    _resetSenderActor();

    // Get one of the three assets randomly
    address asset = _getRandomBaseAsset(i);

    address[] memory assets = new address[](1);
    assets[0] = asset;

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(IPool.mintToTreasury.selector, assets)
    );

    if (success) {
      _after();

      uint256 amountToMint = snapshotGlobalVarsBefore.assetsInfo[asset].aTokenRealTotalSupply -
        snapshotGlobalVarsBefore.assetsInfo[asset].aTokenTotalSupply;
      assertApproxEqAbs(
        snapshotGlobalVarsAfter
          .usersInfo[address(contracts.treasury)]
          .userAssetsInfo[asset]
          .aTokenBalance,
        snapshotGlobalVarsBefore
          .usersInfo[address(contracts.treasury)]
          .userAssetsInfo[asset]
          .aTokenBalance + amountToMint,
        4,
        POOL_HSPOST_A
      );

      assert(true);
    } else {
      revert('PoolHandler: mintToTreasury failed');
    }
  }

  function setUserEMode(uint8 i) external setup {
    bool success;
    bytes memory returnData;

    uint8 eModeCategory = _getRandomEModeCategory(i);

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(IPool.setUserEMode.selector, eModeCategory)
    );

    if (success) {
      _after();

      // POST-CONDITIONS
      if (eModeCategory != snapshotGlobalVarsBefore.usersInfo[address(actor)].userEModeCategory) {
        assertTrue(snapshotGlobalVarsAfter.usersInfo[address(actor)].isHealthy, E_MODE_HSPOST_G);

        for (uint256 j = 0; j < baseAssets.length; j++) {
          if (
            snapshotGlobalVarsAfter
              .usersInfo[address(actor)]
              .userAssetsInfo[baseAssets[j]]
              .vTokenBalance > 0
          ) {
            assertTrue(
              snapshotGlobalVarsAfter.eModesInfo[eModeCategory].isBorrowable[baseAssets[j]],
              E_MODE_HSPOST_H
            );
          }
        }
      }
    } else {
      revert('PoolHandler: setUserEMode failed');
    }
  }

  function eliminateReserveDeficit(uint256 amount, uint8 i) external {
    _setSenderActor(UMBRELLA);

    // Get one of the three assets randomly
    address asset = _getRandomBaseAsset(i);

    uint256 reserveDeficit = pool.getReserveDeficit(asset);

    require(reserveDeficit != 0, 'reserve deficit cannot be 0');

    _mintAndApprove(asset, UMBRELLA, address(pool), amount);

    vm.prank(UMBRELLA);
    pool.supply(asset, amount, UMBRELLA, 0);

    _before();
    vm.prank(UMBRELLA);
    pool.eliminateReserveDeficit(asset, amount);
    _after();

    assertTrue(_isReserveActive(asset), LIQUIDATION_HSPOST_O);

    assertApproxEqAbs(
      snapshotGlobalVarsBefore.assetsInfo[asset].aTokenTotalSupply,
      snapshotGlobalVarsAfter.assetsInfo[asset].aTokenTotalSupply + amount,
      2,
      DM_HSPOST_B
    );

    assertApproxEqAbs(
      snapshotGlobalVarsBefore.usersInfo[UMBRELLA].userAssetsInfo[asset].aTokenBalance,
      snapshotGlobalVarsAfter.usersInfo[UMBRELLA].userAssetsInfo[asset].aTokenBalance + amount,
      2,
      DM_HSPOST_D
    );

    assertEq(
      snapshotGlobalVarsBefore.assetsInfo[asset].virtualUnderlyingBalance,
      snapshotGlobalVarsAfter.assetsInfo[asset].virtualUnderlyingBalance,
      DM_HSPOST_E
    );

    assertEq(snapshotGlobalVarsBefore.usersInfo[UMBRELLA].totalDebtBase, 0, DM_HSPOST_C);

    _resetActorTargets();
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
