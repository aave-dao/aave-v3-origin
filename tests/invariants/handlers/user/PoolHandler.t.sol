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

    address target = address(pool);

    address[] memory assets = new address[](1);
    assets[0] = asset;

    _before();
    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IPool.mintToTreasury.selector, assets)
    );

    if (success) {
      _after();
      assert(true);
    } else {
      revert('PoolHandler: mintToTreasury failed');
    }
  }

  function setUserEMode(uint8 i) external setup {
    bool success;
    bytes memory returnData;

    uint8 eModeCategory = _getRandomEModeCategory(i);

    uint256 previousUserEModeCategory = pool.getUserEMode(address(actor));

    address target = address(pool);

    address[] memory assetsBorrowing = _getUserBorrowingAssets(address(actor));

    _before();
    (success, returnData) = actor.proxy(
      target,
      abi.encodeWithSelector(IPool.setUserEMode.selector, eModeCategory)
    );

    if (success) {
      _after();

      // POST-CONDITIONS
      if (eModeCategory != previousUserEModeCategory) {
        assertAssetsBorrowableInEmode(assetsBorrowing, eModeCategory, E_MODE_HSPOST_H);
        assertGe(_getUserHealthFactor(address(actor)), 1, E_MODE_HSPOST_G);
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

    if (amount > reserveDeficit) {
      amount = reserveDeficit;
    }

    assertApproxEqAbs(
      defaultVarsBefore.totalSupply - amount,
      defaultVarsAfter.totalSupply,
      1,
      DM_HSPOST_B
    );

    assertEq(defaultVarsBefore.users[UMBRELLA].totalDebtBase, 0, DM_HSPOST_C);

    _resetActorTargets();
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
