// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';

// Libraries
import 'src/contracts/protocol/libraries/types/DataTypes.sol';

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title BorrowingHandler
/// @notice Handler test contract for a set of actions
contract BorrowingHandler is BaseHandler {
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
    _setSenderActor(onBehalfOf);

    address asset = _getRandomBaseAsset(j);
    Flags memory flags = _getFlags(asset);

    uint256 userScaledDebtBefore = _getUserScaledDebt(onBehalfOf, asset);

    uint256 onBehalfOfDebtBefore = IERC20(protocolTokens[asset].variableDebtTokenAddress).balanceOf(
      onBehalfOf
    );
    uint256 actorAssetBalanceBefore = IERC20(asset).balanceOf(address(actor));

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

    uint8 eModeCategory = _getUserEModeCategoryId(onBehalfOf);

    if (eModeCategory != 0) {
      if (!_isEModeBorrowableAsset(asset, eModeCategory)) {
        assertEq(userScaledDebtBefore, _getUserScaledDebt(onBehalfOf, asset), E_MODE_GPOST_F);
        assertFalse(success, E_MODE_GPOST_F);
      }
    }

    if (success) {
      _after();
      // POST-CONDITIONS
      if (eModeCategory != 0) {
        assertTrue(_isEModeBorrowableAsset(asset, eModeCategory), E_MODE_HSPOST_A);
      }
      assertTrue(_isBorrowableAsset(asset), E_MODE_GPOST_C);
      assertTrue(defaultVarsBefore.users[_getTargetActor()].isHealthy, BORROWING_HSPOST_B);
      assertTrue(assertReserveIsAbleToBorrow(flags), BORROWING_HSPOST_E);

      assertEq(
        IERC20(asset).balanceOf(address(actor)),
        actorAssetBalanceBefore + amount,
        BORROWING_HSPOST_I
      );
      {
        // Rounding tolerance
        assertApproxEqAbs(
          IERC20(protocolTokens[asset].variableDebtTokenAddress).balanceOf(onBehalfOf),
          onBehalfOfDebtBefore + amount,
          1,
          BORROWING_HSPOST_J
        );
      }
    }
  }

  function repay(uint256 amount, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address onBehalfOf = _getRandomActor(i);
    _setReceiverActor(onBehalfOf);

    address asset = _getRandomBaseAsset(j);
    Flags memory flags = _getFlags(asset);

    address target = address(pool);

    uint256 onBehalfOfDebtBefore = IERC20(protocolTokens[asset].variableDebtTokenAddress).balanceOf(
      onBehalfOf
    );
    uint256 actorAssetBalanceBefore = IERC20(asset).balanceOf(address(actor));

    _before();
    (success, returnData) = actor.proxy(
      target,
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

      amount = amount > onBehalfOfDebtBefore ? onBehalfOfDebtBefore : amount;

      // POST-CONDITIONS
      assertTrue(assertReserveIsActiveAndNotPaused(flags), BORROWING_HSPOST_F);
      assertLe(
        defaultVarsAfter.users[receiverActor].totalDebtBase,
        defaultVarsBefore.users[receiverActor].totalDebtBase,
        BORROWING_HSPOST_A
      );

      assertEq(
        IERC20(asset).balanceOf(address(actor)),
        actorAssetBalanceBefore - amount,
        BORROWING_HSPOST_K
      );

      assertApproxEqAbs(
        IERC20(protocolTokens[asset].variableDebtTokenAddress).balanceOf(onBehalfOf),
        onBehalfOfDebtBefore - amount,
        1,
        BORROWING_HSPOST_L
      );
    }
  }

  function repayWithATokens(uint256 amount, uint8 i) external setup {
    bool success;
    bytes memory returnData;

    address asset = _getRandomBaseAsset(i);
    Flags memory flags = _getFlags(asset);

    address target = address(pool);

    _before();
    (success, returnData) = actor.proxy(
      target,
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
      assertTrue(assertReserveIsActiveAndNotPaused(flags), BORROWING_HSPOST_F);
    }
  }

  function setUserUseReserveAsCollateral(bool useAsCollateral, uint8 i) external setup {
    bool success;
    bytes memory returnData;

    address asset = _getRandomBaseAsset(i);

    address target = address(pool);

    _before();
    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IPool.setUserUseReserveAsCollateral.selector, asset, useAsCollateral)
    );

    if (success) {
      _after();
      assert(true);
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         HANDLER INVARIANTS                                //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function assert_BORROWING_HSPOST_C(uint8 j) external setup {
    bool success;
    bytes memory returnData;

    address asset = _getRandomBaseAsset(j);

    address target = address(pool);

    Flags memory flags = _getFlags(asset);

    uint256 totalOwed = IERC20(protocolTokens[asset].variableDebtTokenAddress).balanceOf(
      address(actor)
    );

    require(totalOwed != 0, 'totalOwed is 0');

    require(assertReserveIsActiveAndNotPaused(flags), 'reserve is not active or paused');

    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(
        IPool.repay.selector,
        asset,
        totalOwed,
        DataTypes.InterestRateMode.VARIABLE,
        address(actor)
      )
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
