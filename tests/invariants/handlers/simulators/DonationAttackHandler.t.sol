// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

// Libraries

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {TestnetERC20} from 'src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title DonationAttackHandler
/// @notice Handler test contract for a set of actions
contract DonationAttackHandler is BaseHandler {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  /// @notice This function transfers any amount of assets to a contract in the system simulating
  /// a big range of donation attacks
  function donateUnderlying(uint256 amount, uint8 i) external {
    TestnetERC20 _token = TestnetERC20(_getRandomBaseAsset(i));

    address target = protocolTokens[address(_token)].aTokenAddress;

    _token.mint(address(this), amount);

    _token.transfer(target, amount);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
