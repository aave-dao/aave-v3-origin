// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';

// Libraries
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from 'src/contracts/protocol/libraries/math/PercentageMath.sol';

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title FlashLoanHandler
/// @notice Handler test contract for a set of actions
contract FlashLoanHandler is BaseHandler {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function flashLoan(
    uint256[3] memory amounts,
    DataTypes.InterestRateMode[3] memory interestRateModes,
    uint256 amountToRepay,
    uint8
  ) external setup {
    bool success;
    bytes memory returnData;

    address target = address(pool);

    address[] memory assets = new address[](3);
    assets[0] = baseAssets[0];
    assets[1] = baseAssets[1];
    assets[2] = baseAssets[2];

    uint256[] memory amountsMemory = new uint256[](3);
    amountsMemory[0] = amounts[0];
    amountsMemory[1] = amounts[1];
    amountsMemory[2] = amounts[2];

    uint256[] memory interestRateModesUint = new uint256[](3);
    interestRateModesUint[0] = uint256(interestRateModes[0]);
    interestRateModesUint[1] = uint256(interestRateModes[1]);
    interestRateModesUint[2] = uint256(interestRateModes[2]);

    bytes memory calldata_ = abi.encodeWithSelector(
      IPool.flashLoan.selector,
      flashLoanReceiver,
      assets,
      amountsMemory,
      interestRateModesUint,
      address(actor),
      abi.encode(amountToRepay, address(actor)),
      0
    );

    _before();
    (success, returnData) = actor.proxy(target, calldata_);

    if (success) {
      _after();
    } else {
      revert('FlashLoanHandler: flashLoan failed');
    }
  }

  function flashLoanSimple(uint256 amount, uint256 amountToRepay, uint8 i) external setup {
    bool success;
    bytes memory returnData;

    address target = address(pool);

    address asset = _getRandomBaseAsset(i);

    uint256[] memory amountsToRepay = new uint256[](1);
    amountsToRepay[0] = amountToRepay;

    _before();
    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(
        IPool.flashLoanSimple.selector,
        flashLoanReceiver,
        asset,
        amount,
        abi.encode(amountsToRepay, address(actor)),
        0
      )
    );

    if (success) {
      _after();
    } else {
      revert('FlashLoanHandler: flashLoanSimple failed');
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
