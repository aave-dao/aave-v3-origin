// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20Detailed, IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';
import {PercentageMath} from 'src/contracts/protocol/libraries/math/PercentageMath.sol';

// Libraries
import 'forge-std/console2.sol';

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title LiquidationHandler
/// @notice Handler test contract for a set of actions
contract LiquidationHandler is BaseHandler {
  using PercentageMath for uint256;
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  uint256 helper_violatorDebtBalanceBefore;
  uint256 helper_violatorDebtReserveValueBefore;
  uint256 helper_violatorCollateralReserveValueBefore;
  uint256 helper_debtAssetDeficitBefore;
  uint256 helper_collateralAssetPrice;
  uint256 helper_debtAssetPrice;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function liquidationCall(
    uint256 debtToCover,
    bool receiveAToken,
    uint8 i,
    uint8 j,
    uint8 k,
    uint8 l
  ) external setup {
    bool success;
    bytes memory returnData;

    address user = _getRandomActor(i);
    _setReceiverActor(user);

    // Set the storage helper variable to the collateral asset
    targetAsset = _getRandomBaseAsset(j);

    helper_violatorCollateralReserveValueBefore = _getUserReserveValueInBaseCurrency(
      targetAsset,
      IERC20(protocolTokens[targetAsset].aTokenAddress).balanceOf(user)
    );

    helper_violatorDebtBalanceBefore = IERC20(
      protocolTokens[_getRandomBaseAsset(k)].variableDebtTokenAddress
    ).balanceOf(user);

    helper_violatorDebtReserveValueBefore = _getUserReserveValueInBaseCurrency(
      _getRandomBaseAsset(k),
      helper_violatorDebtBalanceBefore
    );

    helper_debtAssetDeficitBefore = pool.getReserveDeficit(_getRandomBaseAsset(k));

    helper_collateralAssetPrice = contracts.aaveOracle.getAssetPrice(_getRandomBaseAsset(j));

    helper_debtAssetPrice = contracts.aaveOracle.getAssetPrice(_getRandomBaseAsset(k));

    debtToCover = biasedclampLe(debtToCover, helper_violatorDebtBalanceBefore, l);

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(
        IPool.liquidationCall.selector,
        _getRandomBaseAsset(j),
        _getRandomBaseAsset(k),
        user,
        debtToCover,
        receiveAToken
      )
    );

    if (
      pool.getLiquidationGracePeriod(_getRandomBaseAsset(j)) >= block.timestamp ||
      pool.getLiquidationGracePeriod(_getRandomBaseAsset(k)) >= block.timestamp
    ) {
      assertFalse(success, LIQUIDATION_HSPOST_B);
    }

    if (success) {
      _after();

      // POST-CONDITIONS
      assertFalse(defaultVarsBefore.users[receiverActor].isHealthy, LIQUIDATION_HSPOST_A);

      uint256 violatorDebtReserveValueAfter = _getUserReserveValueInBaseCurrency(
        _getRandomBaseAsset(k),
        IERC20(protocolTokens[_getRandomBaseAsset(k)].variableDebtTokenAddress).balanceOf(user)
      );

      uint256 amountWithCloseFactor = violatorDebtReserveValueAfter.percentMul(
        DEFAULT_LIQUIDATION_CLOSE_FACTOR
      );

      if (violatorDebtReserveValueAfter < violatorDebtReserveValueAfter - amountWithCloseFactor) {
        assertTrue(
          (helper_violatorCollateralReserveValueBefore < MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD ||
            helper_violatorDebtReserveValueBefore < MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD) ||
            defaultVarsBefore.users[user].healthFactor < CLOSE_FACTOR_HF_THRESHOLD,
          LIQUIDATION_HSPOST_F
        );
      }

      uint256 userDebtBalance = IERC20(
        protocolTokens[_getRandomBaseAsset(k)].variableDebtTokenAddress
      ).balanceOf(user);

      {
        uint256 userCollateralBalance = IERC20(protocolTokens[_getRandomBaseAsset(j)].aTokenAddress)
          .balanceOf(user);

        uint256 collateralAssetUnit = 10 ** IERC20Detailed(_getRandomBaseAsset(k)).decimals();
        uint256 debtAssetUnit = 10 ** IERC20Detailed(_getRandomBaseAsset(j)).decimals();

        // to prevent accumulation of dust on the protocol, it is enforced that you either
        // 1. liquidate all debt
        // 2. liquidate all collateral
        // 3. leave more than MIN_LEFTOVER_BASE of collateral & debt
        if (address(actor) != user) {
          assertTrue(
            (userDebtBalance == 0 || userCollateralBalance == 0) ||
              ((userDebtBalance * helper_debtAssetPrice) / debtAssetUnit > MIN_LEFTOVER_BASE &&
                (userCollateralBalance * helper_collateralAssetPrice) / collateralAssetUnit >
                MIN_LEFTOVER_BASE),
            LIQUIDATION_HSPOST_H
          );
        }
      }

      uint256 deficitDelta = pool.getReserveDeficit(_getRandomBaseAsset(k)) -
        helper_debtAssetDeficitBefore;

      if (address(actor) != user) {
        if (deficitDelta != 0) {
          assertEq(defaultVarsAfter.users[user].totalCollateralBase, 0, LIQUIDATION_HSPOST_L);
          assertEq(userDebtBalance, 0, LIQUIDATION_HSPOST_M);
        }
      }

      assertLe(deficitDelta, helper_violatorDebtBalanceBefore, LIQUIDATION_HSPOST_N);

      if (deficitDelta > 0) {
        assertTrue(_isReserveActive(_getRandomBaseAsset(k)), LIQUIDATION_HSPOST_O);
      }
    }

    _deleteLiquidationHelperVars();
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function _deleteLiquidationHelperVars() internal {
    delete helper_violatorDebtBalanceBefore;
    delete helper_violatorCollateralReserveValueBefore;
    delete helper_violatorDebtReserveValueBefore;
    delete helper_debtAssetDeficitBefore;
    delete helper_collateralAssetPrice;
    delete helper_debtAssetPrice;
  }
}
