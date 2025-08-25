// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';

// Libraries
import 'src/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {ICreditDelegationToken} from 'src/contracts/interfaces/ICreditDelegationToken.sol';

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title BorrowingHandler
/// @notice Handler test contract for a set of actions
contract BorrowingHandler is BaseHandler {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function borrow(uint256 amount, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address onBehalfOf = _getRandomActor(i);
    _setReceiverActor(onBehalfOf);

    address asset = _getRandomBaseAsset(j);

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(
        IPool.borrow.selector,
        asset,
        amount,
        DataTypes.InterestRateMode.VARIABLE,
        0,
        onBehalfOf
      )
    );

    uint256 eModeCategory = snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userEModeCategory;

    if (eModeCategory != 0) {
      if (!snapshotGlobalVarsBefore.eModesInfo[eModeCategory].isBorrowable[asset]) {
        assertFalse(success, E_MODE_GPOST_F);
      }
    } else {
      if (!snapshotGlobalVarsBefore.assetsInfo[asset].configuration.getBorrowingEnabled()) {
        assertFalse(success, E_MODE_GPOST_F);
      }
    }

    if (success) {
      _after();
      // POST-CONDITIONS
      if (eModeCategory != 0) {
        assertTrue(
          snapshotGlobalVarsBefore.eModesInfo[eModeCategory].isBorrowable[asset],
          E_MODE_HSPOST_A
        );
      } else {
        assertTrue(snapshotGlobalVarsBefore.assetsInfo[asset].configuration.getBorrowingEnabled());
      }
      assertTrue(snapshotGlobalVarsBefore.usersInfo[onBehalfOf].isHealthy, BORROWING_HSPOST_B);
      assertTrue(snapshotGlobalVarsAfter.usersInfo[onBehalfOf].isHealthy, BORROWING_HSPOST_B);

      assertEq(
        snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].underlyingBalance,
        snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].underlyingBalance +
          amount,
        BORROWING_HSPOST_I
      );

      if (address(actor) != onBehalfOf) {
        assertApproxEqAbs(
          snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].borrowAllowances[
            address(actor)
          ] + amount,
          snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].borrowAllowances[
            address(actor)
          ],
          2
        );
        assertLe(
          snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].borrowAllowances[
            address(actor)
          ] + amount,
          snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].borrowAllowances[
            address(actor)
          ],
          ''
        );
      }

      assertApproxEqAbs(
        snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].vTokenBalance,
        snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].vTokenBalance + amount,
        2,
        BORROWING_HSPOST_J
      );
      assertGe(
        snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].vTokenBalance,
        snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].vTokenBalance + amount,
        BORROWING_HSPOST_J
      );

      assertEq(
        snapshotGlobalVarsBefore.assetsInfo[asset].virtualUnderlyingBalance,
        snapshotGlobalVarsAfter.assetsInfo[asset].virtualUnderlyingBalance + amount,
        BORROWING_HSPOST_N
      );
    } else {
      revert('BorrowingHandler: borrow action reverted');
    }
  }

  function repay(uint256 amount, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address onBehalfOf = _getRandomActor(i);
    _setReceiverActor(onBehalfOf);

    address asset = _getRandomBaseAsset(j);

    _before();
    _mintAndApprove({token: asset, owner: address(actor), spender: address(pool), amount: amount});

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(
        IPool.repay.selector,
        asset,
        amount,
        DataTypes.InterestRateMode.VARIABLE,
        onBehalfOf
      )
    );

    if (success) {
      _after();

      // POST-CONDITIONS
      assertEq(
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].underlyingBalance +
          amount,
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].underlyingBalance,
        BORROWING_HSPOST_K
      );

      assertApproxEqAbs(
        snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].vTokenBalance,
        snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].vTokenBalance + amount,
        2
      );
      assertGe(
        snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].vTokenBalance,
        snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].vTokenBalance + amount,
        ''
      );

      assertEq(
        snapshotGlobalVarsAfter.assetsInfo[asset].virtualUnderlyingBalance,
        snapshotGlobalVarsBefore.assetsInfo[asset].virtualUnderlyingBalance + amount,
        BORROWING_HSPOST_O
      );
    } else {
      revert('BorrowingHandler: repay action reverted');
    }
  }

  function repayWithATokens(uint256 amount, uint8 i) external setup {
    bool success;
    bytes memory returnData;

    address asset = _getRandomBaseAsset(i);

    _before();
    _approve({token: asset, actor_: actor, spender: address(pool), amount: amount});

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(
        IPool.repayWithATokens.selector,
        asset,
        amount,
        DataTypes.InterestRateMode.VARIABLE
      )
    );

    if (success) {
      _after();

      // POST-CONDITIONS
      assertEq(
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].underlyingBalance,
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].underlyingBalance,
        BORROWING_HSPOST_K
      );

      assertApproxEqAbs(
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].vTokenBalance,
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].vTokenBalance +
          amount,
        2
      );
      assertGe(
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].vTokenBalance,
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].vTokenBalance +
          amount,
        ''
      );

      assertApproxEqAbs(
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].aTokenBalance,
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].aTokenBalance +
          amount,
        2,
        BORROWING_HSPOST_P
      );
      assertGe(
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].aTokenBalance,
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].aTokenBalance +
          amount,
        BORROWING_HSPOST_P
      );

      assertEq(
        snapshotGlobalVarsAfter.assetsInfo[asset].virtualUnderlyingBalance,
        snapshotGlobalVarsBefore.assetsInfo[asset].virtualUnderlyingBalance,
        BORROWING_HSPOST_O
      );
    } else {
      revert('BorrowingHandler: repay with aTokens action reverted');
    }
  }

  function setUserUseReserveAsCollateral(bool useAsCollateral, uint8 i) external setup {
    bool success;
    bytes memory returnData;

    address asset = _getRandomBaseAsset(i);

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(IPool.setUserUseReserveAsCollateral.selector, asset, useAsCollateral)
    );

    if (success) {
      _after();
      assert(true);
    } else {
      revert('BorrowingHandler: setUserUseReserveAsCollateral action reverted');
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
