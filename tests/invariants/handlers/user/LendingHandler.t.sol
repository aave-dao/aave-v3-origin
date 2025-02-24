// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';

// Libraries

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title LendingHandler
/// @notice Handler test contract for a set of actions
contract LendingHandler is BaseHandler {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function supply(uint256 amount, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address onBehalfOf = _getRandomActor(i);
    _setReceiverActor(onBehalfOf);

    address asset = _getRandomBaseAsset(j);
    Flags memory flags = _getFlags(asset);

    address target = address(pool);

    uint256 senderUnderlyingBalanceBefore = IERC20(asset).balanceOf(address(actor));
    uint256 onBehalfOfATokenBalanceBefore = IERC20(protocolTokens[asset].aTokenAddress).balanceOf(
      onBehalfOf
    );

    _before();
    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IPool.supply.selector, asset, amount, onBehalfOf, 0)
    );

    if (success) {
      _after();

      // POST-CONDITIONS
      assertTrue(assertReserveIsAbleToDeposit(flags), LENDING_HPOST_A);
      assertEq(
        IERC20(asset).balanceOf(address(actor)),
        senderUnderlyingBalanceBefore - amount,
        LENDING_HPOST_D
      );

      assertApproxEqAbs(
        IERC20(protocolTokens[asset].aTokenAddress).balanceOf(onBehalfOf),
        onBehalfOfATokenBalanceBefore + amount,
        1,
        LENDING_HPOST_E
      );
    } else {
      revert('LendingHandler: supply failed');
    }
  }

  function withdraw(uint256 amount, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address to = _getRandomActor(i);

    address asset = _getRandomBaseAsset(j);
    Flags memory flags = _getFlags(asset);

    bool isCollateral = _isUsingAsCollateral(asset, address(actor));

    uint256 toUnderlyingBalanceBefore = IERC20(asset).balanceOf(to);
    uint256 actorATokenBalanceBefore = IERC20(protocolTokens[asset].aTokenAddress).balanceOf(
      address(actor)
    );

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(IPool.withdraw.selector, asset, amount, to)
    );

    if (success) {
      _after();

      // POST-CONDITIONS
      assertTrue(assertReserveIsActiveAndNotPaused(flags), LENDING_HPOST_A);

      /// @dev LENDING_HPOST_F
      uint256 aTokenBalance = IERC20(protocolTokens[asset].aTokenAddress).balanceOf(address(actor));
      assertApproxEqAbs(aTokenBalance, actorATokenBalanceBefore - amount, 1, LENDING_HPOST_F);

      /// @dev LENDING_HPOST_G
      assertEq(IERC20(asset).balanceOf(to), toUnderlyingBalanceBefore + amount, LENDING_HPOST_G);

      if (isCollateral) {
        assertTrue(defaultVarsBefore.users[address(actor)].isHealthy, LENDING_HPOST_H1);
        assertTrue(defaultVarsAfter.users[address(actor)].isHealthy, LENDING_HPOST_H2);
      }
    } else {
      revert('LendingHandler: withdraw failed');
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         HANDLER INVARIANTS                                //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function assert_BORROWING_HSPOST_G(uint8 i) external setup {
    bool success;
    bytes memory returnData;

    address asset = _getRandomBaseAsset(i);

    address target = address(pool);

    Flags memory flags = _getFlags(asset);

    uint256 totalDebt = IERC20(protocolTokens[asset].variableDebtTokenAddress).totalSupply();

    require(totalDebt == 0, 'totalDebt is not 0');

    require(!_isBorrowingAny(address(actor)), 'user has debt');

    uint256 amount = IERC20(protocolTokens[asset].aTokenAddress).balanceOf(address(actor));

    require(amount > 0, 'amount is 0');

    require(assertReserveIsActiveAndNotPaused(flags), 'reserve is not active or paused');

    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IPool.withdraw.selector, asset, amount, address(actor))
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
