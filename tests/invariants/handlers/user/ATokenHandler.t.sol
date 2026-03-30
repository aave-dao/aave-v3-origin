// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';

// Contracts
import {IncentivizedERC20} from 'src/contracts/protocol/tokenization/base/IncentivizedERC20.sol';

// Libraries

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title ATokenHandler
/// @notice Handler test contract for a set of actions
contract ATokenHandler is BaseHandler {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function approve(uint256 amount, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address spender = _getRandomActor(i);

    address target = _getRandomAToken(j);

    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IERC20.approve.selector, spender, amount)
    );

    if (success) {
      assert(true);
    } else {
      revert('ATokenHandler: approve failed');
    }
  }

  function transfer(uint256 amount, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address recipient = _getRandomActor(i);
    _setReceiverActor(recipient);

    address underlyingToken = _getRandomBaseAsset(j);
    address aToken = _getRandomAToken(j);

    _before();
    (success, returnData) = actor.proxy(
      aToken,
      abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
    );

    if (success) {
      _after();

      if (
        (amount != 0 && address(actor) != recipient) &&
        _isUsingAsCollateral(underlyingToken, address(actor))
      ) {
        assertTrue(snapshotGlobalVarsAfter.usersInfo[address(actor)].isHealthy, ERC20_HSPOST_A);
        assertTrue(snapshotGlobalVarsBefore.usersInfo[address(actor)].isHealthy, ERC20_HSPOST_B);
      }

      assertApproxEqAbs(
        snapshotGlobalVarsAfter
          .usersInfo[address(actor)]
          .userAssetsInfo[underlyingToken]
          .aTokenBalance + amount,
        snapshotGlobalVarsBefore
          .usersInfo[address(actor)]
          .userAssetsInfo[underlyingToken]
          .aTokenBalance,
        2,
        ERC20_HSPOST_E
      );

      assertApproxEqAbs(
        snapshotGlobalVarsBefore
          .usersInfo[recipient]
          .userAssetsInfo[underlyingToken]
          .aTokenBalance + amount,
        snapshotGlobalVarsAfter.usersInfo[recipient].userAssetsInfo[underlyingToken].aTokenBalance,
        2,
        ERC20_HSPOST_F
      );
    } else {
      revert('ATokenHandler: transfer failed');
    }
  }

  function transferFrom(uint256 amount, uint8 i, uint8 j, uint256 u) external setup {
    bool success;
    bytes memory returnData;

    address owner = _getRandomActor(i);

    address recipient = _getRandomActor(u);

    address underlyingToken = _getRandomBaseAsset(j);
    address aToken = _getRandomAToken(j);

    _before();
    (success, returnData) = actor.proxy(
      aToken,
      abi.encodeWithSelector(IERC20.transferFrom.selector, owner, recipient, amount)
    );

    if (success) {
      _after();

      if (
        amount != 0 &&
        owner != recipient &&
        snapshotGlobalVarsAfter.usersInfo[owner].userAssetsInfo[underlyingToken].isUsingAsCollateral
      ) {
        assertTrue(snapshotGlobalVarsAfter.usersInfo[owner].isHealthy, ERC20_HSPOST_C);
        assertTrue(snapshotGlobalVarsBefore.usersInfo[owner].isHealthy, ERC20_HSPOST_D);
      }

      if (
        snapshotGlobalVarsBefore
          .usersInfo[owner]
          .userAssetsInfo[underlyingToken]
          .underlyingAllowances[address(actor)] != type(uint256).max
      ) {
        assertApproxEqAbs(
          snapshotGlobalVarsAfter
            .usersInfo[owner]
            .userAssetsInfo[underlyingToken]
            .underlyingAllowances[address(actor)] + amount,
          snapshotGlobalVarsBefore
            .usersInfo[owner]
            .userAssetsInfo[underlyingToken]
            .underlyingAllowances[address(actor)],
          2,
          ERC20_HSPOST_E
        );
        assertLe(
          snapshotGlobalVarsAfter
            .usersInfo[owner]
            .userAssetsInfo[underlyingToken]
            .underlyingAllowances[address(actor)] + amount,
          snapshotGlobalVarsBefore
            .usersInfo[owner]
            .userAssetsInfo[underlyingToken]
            .underlyingAllowances[address(actor)],
          ERC20_HSPOST_E
        );
      } else {
        assertEq(
          snapshotGlobalVarsAfter
            .usersInfo[owner]
            .userAssetsInfo[underlyingToken]
            .underlyingAllowances[address(actor)],
          type(uint256).max
        );
      }

      assertApproxEqAbs(
        snapshotGlobalVarsAfter.usersInfo[owner].userAssetsInfo[underlyingToken].aTokenBalance +
          amount,
        snapshotGlobalVarsBefore.usersInfo[owner].userAssetsInfo[underlyingToken].aTokenBalance,
        2,
        ERC20_HSPOST_E
      );
      assertLe(
        snapshotGlobalVarsAfter.usersInfo[owner].userAssetsInfo[underlyingToken].aTokenBalance +
          amount,
        snapshotGlobalVarsBefore.usersInfo[owner].userAssetsInfo[underlyingToken].aTokenBalance,
        ERC20_HSPOST_E
      );

      assertApproxEqAbs(
        snapshotGlobalVarsBefore
          .usersInfo[recipient]
          .userAssetsInfo[underlyingToken]
          .aTokenBalance + amount,
        snapshotGlobalVarsAfter.usersInfo[recipient].userAssetsInfo[underlyingToken].aTokenBalance,
        2,
        ERC20_HSPOST_F
      );
      assertGe(
        snapshotGlobalVarsBefore
          .usersInfo[recipient]
          .userAssetsInfo[underlyingToken]
          .aTokenBalance + amount,
        snapshotGlobalVarsAfter.usersInfo[recipient].userAssetsInfo[underlyingToken].aTokenBalance,
        ERC20_HSPOST_F
      );
    } else {
      revert('ATokenHandler: transferFrom failed');
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function rescueTokens(uint256 amount, uint8 i, uint8 j) external {
    address target = _getRandomAToken(i);

    address token = _getRandomBaseAsset(j);

    _before();
    IAToken(target).rescueTokens(token, address(this), amount);
    _after();
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
