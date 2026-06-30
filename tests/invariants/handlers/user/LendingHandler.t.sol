// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
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

    _mintAndApprove({token: asset, owner: address(actor), spender: address(pool), amount: amount});

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(IPool.supply.selector, asset, amount, onBehalfOf, 0)
    );

    if (success) {
      _after();

      // POST-CONDITIONS
      assertEq(
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].underlyingBalance,
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].underlyingBalance +
          amount,
        LENDING_HPOST_D
      );

      assertEq(
        snapshotGlobalVarsBefore.assetsInfo[asset].virtualUnderlyingBalance + amount,
        snapshotGlobalVarsAfter.assetsInfo[asset].virtualUnderlyingBalance
      );

      assertApproxEqAbs(
        snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].aTokenBalance + amount,
        snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].aTokenBalance,
        2,
        LENDING_HPOST_E
      );
      assertGe(
        snapshotGlobalVarsBefore.usersInfo[onBehalfOf].userAssetsInfo[asset].aTokenBalance + amount,
        snapshotGlobalVarsAfter.usersInfo[onBehalfOf].userAssetsInfo[asset].aTokenBalance,
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

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(IPool.withdraw.selector, asset, amount, to)
    );

    if (success) {
      _after();

      // POST-CONDITIONS
      assertEq(
        snapshotGlobalVarsBefore.usersInfo[to].userAssetsInfo[asset].underlyingBalance + amount,
        snapshotGlobalVarsAfter.usersInfo[to].userAssetsInfo[asset].underlyingBalance
      );

      assertEq(
        snapshotGlobalVarsAfter.assetsInfo[asset].virtualUnderlyingBalance + amount,
        snapshotGlobalVarsBefore.assetsInfo[asset].virtualUnderlyingBalance
      );

      assertApproxEqAbs(
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].aTokenBalance +
          amount,
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].aTokenBalance,
        2
      );
      assertLe(
        snapshotGlobalVarsAfter.usersInfo[address(actor)].userAssetsInfo[asset].aTokenBalance +
          amount,
        snapshotGlobalVarsBefore.usersInfo[address(actor)].userAssetsInfo[asset].aTokenBalance,
        ''
      );
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
