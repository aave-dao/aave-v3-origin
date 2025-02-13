// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
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

    address target = _getRandomAToken(j);

    _before();
    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
    );

    if (success) {
      _after();

      if (
        (amount != 0 && address(actor) != recipient) &&
        _isUsingAsCollateral(_getRandomBaseAsset(j), address(actor))
      ) {
        assertTrue(defaultVarsAfter.users[address(actor)].isHealthy, ERC20_HSPOST_A);
        assertTrue(defaultVarsBefore.users[address(actor)].isHealthy, ERC20_HSPOST_B);
      }
    } else {
      revert('ATokenHandler: transfer failed');
    }
  }

  function transferFrom(uint256 amount, uint8 i, uint8 j, uint256 u) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address sender = _getRandomActor(i);
    _setSenderActor(sender);

    // Get one of the three actors randomly
    address recipient = _getRandomActor(u);

    address target = _getRandomAToken(j);

    _before();
    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IERC20.transferFrom.selector, sender, recipient, amount)
    );

    if (success) {
      _after();

      if (amount != 0 && sender != recipient) {
        assertTrue(defaultVarsAfter.users[sender].isHealthy, ERC20_HSPOST_C);
        assertTrue(defaultVarsBefore.users[sender].isHealthy, ERC20_HSPOST_D);
      }
    } else {
      revert('ATokenHandler: transferFrom failed');
    }
  }

  function increaseAllowance(uint256 addedValue, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address spender = _getRandomActor(i);

    address target = _getRandomAToken(j);

    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IncentivizedERC20.increaseAllowance.selector, spender, addedValue)
    );

    if (success) {
      assert(true);
    } else {
      revert('ATokenHandler: increaseAllowance failed');
    }
  }

  function decreaseAllowance(uint256 subtractedValue, uint8 i, uint8 j) external setup {
    bool success;
    bytes memory returnData;

    // Get one of the three actors randomly
    address spender = _getRandomActor(i);

    address target = _getRandomAToken(j);

    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IncentivizedERC20.decreaseAllowance.selector, spender, subtractedValue)
    );

    if (success) {
      assert(true);
    } else {
      revert('ATokenHandler: decreaseAllowance failed');
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
