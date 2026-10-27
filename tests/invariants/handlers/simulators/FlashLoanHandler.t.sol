// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';

// Libraries
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from 'src/contracts/protocol/libraries/math/PercentageMath.sol';
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title FlashLoanHandler
/// @notice Handler test contract for a set of actions
contract FlashLoanHandler is BaseHandler {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function flashLoan(
    uint256[3] memory amounts,
    bool[3] memory interestRateModes,
    uint8 i
  ) external setup {
    bool success;
    bytes memory returnData;

    address[] memory assets = new address[](3);
    assets[0] = baseAssets[0];
    assets[1] = baseAssets[1];
    assets[2] = baseAssets[2];

    uint256[] memory interestRateModesUint = new uint256[](3);
    interestRateModesUint[0] = interestRateModes[0] ? 2 : 0;
    interestRateModesUint[1] = interestRateModes[1] ? 2 : 0;
    interestRateModesUint[2] = interestRateModes[2] ? 2 : 0;

    address onBehalfOf = _getRandomActor(i);

    bytes memory calldata_ = abi.encodeWithSelector(
      IPool.flashLoan.selector,
      flashLoanReceiver,
      assets,
      amounts,
      interestRateModesUint,
      onBehalfOf,
      '',
      0
    );

    _before();
    (success, returnData) = actor.proxy(address(pool), calldata_);

    if (success) {
      _after();
    } else {
      revert('FlashLoanHandler: flashLoan failed');
    }
  }

  function flashLoanSimple(uint256 amount, uint8 i) external setup {
    bool success;
    bytes memory returnData;

    address asset = _getRandomBaseAsset(i);

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(
        IPool.flashLoanSimple.selector,
        flashLoanReceiver,
        asset,
        amount,
        '',
        0
      )
    );

    if (success) {
      _after();
    } else {
      revert('FlashLoanHandler: flashLoanSimple failed');
    }
  }

  /// @notice Drives protected Pool actions from inside a simple flashloan callback.
  function flashLoanSimpleComposable(uint8 assetIndex, uint8 action) external setup {
    address asset = _getRandomBaseAsset(assetIndex);
    DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(asset);

    if (
      !configuration.getFlashLoanEnabled() ||
      !configuration.getActive() ||
      configuration.getPaused()
    ) return;

    uint256 available = pool.getVirtualUnderlyingBalance(asset);
    uint256 actualBalance = IERC20(asset).balanceOf(pool.getReserveData(asset).aTokenAddress);
    uint256 totalSupply = IERC20(pool.getReserveData(asset).aTokenAddress).totalSupply();
    if (available == 0 || actualBalance == 0 || totalSupply == 0) return;

    uint256 amount = available > 1e6 ? 1e6 : available;
    if (amount > actualBalance) amount = actualBalance;
    if (amount > totalSupply) amount = totalSupply;

    uint256 callbacksBefore = reentrantFlashLoanReceiver.callbackCount();
    reentrantFlashLoanReceiver.setATokenSource(address(actor));
    reentrantFlashLoanReceiver.configure(action % 2);

    (bool success, ) = address(pool).call(
      abi.encodeCall(
        IPool.flashLoanSimple,
        (address(reentrantFlashLoanReceiver), asset, amount, bytes(''), 0)
      )
    );

    if (
      !success ||
      !reentrantFlashLoanReceiver.callbackEntered() ||
      reentrantFlashLoanReceiver.guardBlockedCall() ||
      reentrantFlashLoanReceiver.callbackCount() != callbacksBefore + 1
    ) {
      flashLoanComposabilityFailed = true;
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
