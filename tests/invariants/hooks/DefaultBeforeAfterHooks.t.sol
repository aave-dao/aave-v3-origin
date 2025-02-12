// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Libraries
import {Strings} from '../utils/Pretty.sol';
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';

// Test Contracts
import {BaseHooks} from '../base/BaseHooks.t.sol';

// Interfaces
import {ILendingHandler} from '../handlers/interfaces/ILendingHandler.sol';
import {IBorrowingHandler} from '../handlers/interfaces/IBorrowingHandler.sol';
import {ILiquidationHandler} from '../handlers/interfaces/ILiquidationHandler.sol';
import {IPoolHandler} from '../handlers/interfaces/IPoolHandler.sol';
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';
import {IATokenHandler} from '../handlers/interfaces/IATokenHandler.sol';

/// @title Default Before After Hooks
/// @notice Helper contract for before and after hooks
/// @dev This contract is inherited by handlers
abstract contract DefaultBeforeAfterHooks is BaseHooks {
  using Strings for string;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         STRUCTS                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  struct User {
    uint256 totalCollateralBase;
    uint256 totalDebtBase;
    uint256 currentLiquidationThreshold;
    uint256 ltv;
    uint256 healthFactor;
    bool isHealthy;
  }

  struct DefaultVars {
    // Pool
    uint256[] reseveNormalizedIncome;
    uint256[] reserveNormalizedVariableDebt;
    uint256[] virtualUnderlyingBalance;
    // Reserve
    uint256 totalSupply;
    uint256 scaledTotalSupply;
    uint256 totalBorrow;
    uint256 supplyCap;
    uint256 borrowCap;
    uint256 accruedToTreasury;
    uint256 reserveDeficit;
    // User
    mapping(address => User) users;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                       HOOKS STORAGE                                       //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  DefaultVars defaultVarsBefore;
  DefaultVars defaultVarsAfter;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           SETUP                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  /// @notice Default hooks setup
  function _setUpDefaultHooks() internal {
    // Before
    _setUpDefaultVars(defaultVarsBefore);
    // After
    _setUpDefaultVars(defaultVarsAfter);
  }

  /// @notice Helper to initialize storage arrays of default vars
  function _setUpDefaultVars(DefaultVars storage _dafaultVars) internal {
    for (uint256 i; i < baseAssets.length; i++) {
      _dafaultVars.reseveNormalizedIncome.push(0);
      _dafaultVars.reserveNormalizedVariableDebt.push(0);
      _dafaultVars.virtualUnderlyingBalance.push(0);
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HOOKS                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function _defaultHooksBefore() internal {
    // Reserve & configuration
    _setReserveValues(defaultVarsBefore);

    // Health & user account data
    _setUserValues(defaultVarsBefore);
  }

  function _defaultHooksAfter() internal {
    // Reserve & configuration
    _setReserveValues(defaultVarsAfter);
    // Health & user account data
    _setUserValues(defaultVarsAfter);
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                       HELPERS                                             //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function _setReserveValues(DefaultVars storage _defaultVars) internal {
    // Values across all reserves
    for (uint256 i; i < baseAssets.length; i++) {
      address asset = baseAssets[i];
      // Pool
      _defaultVars.reseveNormalizedIncome[i] = _getReserveNormalizedIncome(asset);
      _defaultVars.reserveNormalizedVariableDebt[i] = _getReserveNormalizedVariableDebt(asset);
      _defaultVars.virtualUnderlyingBalance[i] = pool.getVirtualUnderlyingBalance(asset);
    }

    // Values of the target reserve
    if (targetAsset != address(0)) {
      _defaultVars.totalSupply = _getRealTotalSupply(targetAsset);
      _defaultVars.scaledTotalSupply = IAToken(protocolTokens[targetAsset].aTokenAddress)
        .scaledTotalSupply();
      _defaultVars.totalBorrow = IERC20(protocolTokens[targetAsset].variableDebtTokenAddress)
        .totalSupply();
      _defaultVars.accruedToTreasury = pool.getReserveData(targetAsset).accruedToTreasury;
      // Reserve configuration
      DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(targetAsset);
      _defaultVars.supplyCap =
        currentConfig.getSupplyCap() *
        10 ** IERC20Detailed(targetAsset).decimals();
      _defaultVars.borrowCap =
        currentConfig.getBorrowCap() *
        10 ** IERC20Detailed(targetAsset).decimals();
      _defaultVars.reserveDeficit = pool.getReserveDeficit(targetAsset);
    }
  }

  function _setUserValues(DefaultVars storage _defaultVars) internal {
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      User storage _user = _defaultVars.users[actorAddresses[i]];
      (
        _user.totalCollateralBase,
        _user.totalDebtBase,
        ,
        _user.currentLiquidationThreshold,
        _user.ltv,
        _user.healthFactor
      ) = pool.getUserAccountData(actorAddresses[i]);
      _user.isHealthy = _isHealthy(_user.healthFactor);
    }
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                   POST CONDITIONS: BASE                                   //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_BASE_GPOST_A() internal {
    for (uint256 i; i < baseAssets.length; i++) {
      assertLe(
        defaultVarsBefore.reseveNormalizedIncome[i],
        defaultVarsAfter.reseveNormalizedIncome[i],
        BASE_GPOST_A
      );

      assertLe(
        defaultVarsBefore.reserveNormalizedVariableDebt[i],
        defaultVarsAfter.reserveNormalizedVariableDebt[i],
        BASE_GPOST_A
      );
    }
  }

  function assert_BASE_GPOST_BCD() internal {
    for (uint256 i; i < baseAssets.length; i++) {
      if (
        defaultVarsBefore.reserveNormalizedVariableDebt[i] !=
        defaultVarsAfter.reserveNormalizedVariableDebt[i]
      ) {
        assertTrue(
          msg.sig == ILendingHandler.supply.selector ||
            msg.sig == ILendingHandler.withdraw.selector ||
            msg.sig == IBorrowingHandler.borrow.selector ||
            msg.sig == IBorrowingHandler.repay.selector ||
            msg.sig == ILiquidationHandler.liquidationCall.selector,
          BASE_GPOST_B
        );
      }
      if (
        defaultVarsBefore.virtualUnderlyingBalance[i] !=
        defaultVarsAfter.virtualUnderlyingBalance[i]
      ) {
        assertTrue(
          msg.sig == ILendingHandler.supply.selector ||
            msg.sig == ILendingHandler.withdraw.selector ||
            msg.sig == IBorrowingHandler.borrow.selector ||
            msg.sig == IBorrowingHandler.repay.selector ||
            msg.sig == ILiquidationHandler.liquidationCall.selector,
          BASE_GPOST_C
        );
      }

      if (
        defaultVarsBefore.reseveNormalizedIncome[i] != defaultVarsAfter.reseveNormalizedIncome[i]
      ) {
        assertTrue(
          msg.sig == ILendingHandler.supply.selector ||
            msg.sig == ILendingHandler.withdraw.selector ||
            msg.sig == IBorrowingHandler.borrow.selector ||
            msg.sig == IBorrowingHandler.repay.selector ||
            msg.sig == ILiquidationHandler.liquidationCall.selector,
          BASE_GPOST_D
        );
      }
    }
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                 POST CONDITIONS: LENDING                                  //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_LENDING_GPOST_C() internal {
    if (targetAsset == address(0)) return;
    uint256 totalSupplyUpdatedTreasury = _getRealTotalSupply(
      targetAsset,
      defaultVarsBefore.scaledTotalSupply,
      defaultVarsAfter.accruedToTreasury
    );

    if (totalSupplyUpdatedTreasury < defaultVarsAfter.totalSupply) {
      if (defaultVarsAfter.supplyCap != 0 && msg.sig != IPoolHandler.mintToTreasury.selector)
        assertLe(defaultVarsAfter.totalSupply, defaultVarsAfter.supplyCap, LENDING_GPOST_C);
    }
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                 POST CONDITIONS: BORROWING                                  //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_BORROWING_GPOST_H() internal {
    if (defaultVarsBefore.totalBorrow < defaultVarsAfter.totalBorrow) {
      if (defaultVarsAfter.borrowCap != 0)
        assertLe(defaultVarsAfter.totalBorrow, defaultVarsAfter.borrowCap, BORROWING_GPOST_H);
    }
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                POST CONDITIONS: HEALTH FACTOR                             //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_HF_GPOST_A(address user) internal {
    if (defaultVarsAfter.users[user].healthFactor < defaultVarsBefore.users[user].healthFactor) {
      // if a user hf has decreased check that the function called is not in isNonDecreasingHfAction
      // and that the user is active

      assertFalse(isNonDecreasingHfAction[msg.sig], HF_GPOST_A);
    }
  }

  function assert_HF_GPOST_B(address user) internal {
    if (defaultVarsAfter.users[user].healthFactor > defaultVarsBefore.users[user].healthFactor) {
      // if a user hf has increased check that the function called is not in isNonIncreasingHfAction
      // and that the user is active
      assertFalse(isNonIncreasingHfAction[msg.sig], HF_GPOST_B);
    }
  }

  function assert_HF_GPOST_C(address user) internal {
    if (defaultVarsBefore.users[user].isHealthy && !defaultVarsAfter.users[user].isHealthy) {
      assertTrue(msg.sig == IPoolHandler.configureReserveAsCollateral.selector, HF_GPOST_C);
    }
  }

  function assert_HF_GPOST_D(address user) internal {
    /// @dev this check makes sure the property is only checked against target actors in targetted functions
    if (_isActiveActor(user)) {
      if (!defaultVarsAfter.users[user].isHealthy) {
        assertTrue(isHfUnsafeAfterAction[msg.sig], HF_GPOST_D);
      }
    }
  }

  function assert_HF_GPOST_E(address user) internal {
    /// @dev this check makes sure the property is only checked against target actors in targetted functions
    if (_isActiveActor(user)) {
      if (!defaultVarsAfter.users[user].isHealthy) {
        assertTrue(isHfUnsafeBeforeAction[msg.sig], HF_GPOST_E);
      }
    }
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                   POST CONDITIONS: DEFICIT                                //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_DM_GPOST_A() internal {
    if (defaultVarsBefore.reserveDeficit > defaultVarsAfter.reserveDeficit) {
      assertTrue(msg.sig == IPoolHandler.eliminateReserveDeficit.selector, DM_GPOST_A);
    }
  }
}
