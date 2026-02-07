// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Libraries
import {Strings} from '../utils/Pretty.sol';
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {EModeConfiguration} from 'src/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {UserConfiguration} from 'src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
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
import {ICreditDelegationToken} from 'src/contracts/interfaces/ICreditDelegationToken.sol';
import {IVariableDebtToken} from 'src/contracts/interfaces/IVariableDebtToken.sol';
import {IATokenHandler} from '../handlers/interfaces/IATokenHandler.sol';

/// @title Default Before After Hooks
/// @notice Helper contract for before and after hooks
/// @dev This contract is inherited by handlers
abstract contract DefaultBeforeAfterHooks is BaseHooks {
  using Strings for string;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         STRUCTS                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  struct UserAssetInfo {
    uint256 underlyingBalance;
    uint256 aTokenBalance;
    uint256 aTokenBalanceInBaseCurrency;
    uint256 aTokenScaledBalance;
    uint256 vTokenBalance;
    uint256 vTokenBalanceInBaseCurrency;
    uint256 vTokenScaledBalance;
    bool isUsingAsCollateral;
    mapping(address user => uint256) underlyingAllowances;
    mapping(address user => uint256) aTokenAllowances;
    mapping(address user => uint256) borrowAllowances;
  }

  struct UserInfo {
    uint256 totalCollateralBase;
    uint256 totalDebtBase;
    uint256 liquidationThreshold;
    uint256 ltv;
    uint256 healthFactor;
    bool isHealthy;
    uint256 userEModeCategory;
    mapping(address underlyingToken => UserAssetInfo) userAssetsInfo;
  }

  struct AssetInfo {
    uint256 underlyingTotalSupply;
    uint256 aTokenTotalSupply;
    uint256 aTokenRealTotalSupply;
    uint256 aTokenScaledTotalSupply;
    uint256 vTokenTotalSupply;
    uint256 vTokenScaledTotalSupply;
    uint256 virtualUnderlyingBalance;
    uint256 accruedToTreasury;
    uint256 reserveDeficit;
    uint256 liquidationGracePeriodUntil;
    DataTypes.ReserveConfigurationMap configuration;
    uint256 pendingLtv;
    uint256 liquidityIndex;
    uint256 liquidityRate;
    uint256 variableBorrowIndex;
    uint256 variableBorrowRate;
  }

  struct EModeInfo {
    bool isEnabled;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint128 collateralBitmap;
    uint128 borrowableBitmap;
    uint128 ltvzeroBitmap;
    address[] collateralAssets;
    address[] borrowableAssets;
    address[] ltvZeroAssets;
    mapping(address asset => bool) isCollateral;
    mapping(address asset => bool) isBorrowable;
    mapping(address asset => bool) isLtvZero;
  }

  struct SnapshotGlobalVars {
    mapping(address underlyingToken => AssetInfo) assetsInfo;
    mapping(uint256 eModeCategory => EModeInfo) eModesInfo;
    mapping(address user => UserInfo) usersInfo;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                       HOOKS STORAGE                                       //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  SnapshotGlobalVars internal snapshotGlobalVarsBefore;
  SnapshotGlobalVars internal snapshotGlobalVarsAfter;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HOOKS                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function _defaultHooksBefore() internal {
    _makeSnapshot(snapshotGlobalVarsBefore);
  }

  function _defaultHooksAfter() internal {
    _makeSnapshot(snapshotGlobalVarsAfter);
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                       HELPERS                                             //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function _makeSnapshot(SnapshotGlobalVars storage _snapshotGlobalVars) internal {
    for (uint256 i = 0; i < baseAssets.length; ++i) {
      _makeAssetSnapshot(_snapshotGlobalVars.assetsInfo[baseAssets[i]], baseAssets[i]);
    }

    for (uint256 i = 0; i < NUMBER_OF_ACTORS; ++i) {
      _makeUserSnapshot(_snapshotGlobalVars.usersInfo[actorAddresses[i]], actorAddresses[i]);
    }
    _makeUserSnapshot(_snapshotGlobalVars.usersInfo[UMBRELLA], UMBRELLA);
    _makeUserSnapshot(
      _snapshotGlobalVars.usersInfo[address(contracts.treasury)],
      address(contracts.treasury)
    );

    for (uint256 i = 0; i < type(uint8).max; ++i) {
      _makeEModeSnapshot({_eModeSnapshot: _snapshotGlobalVars.eModesInfo[i], eModeCategory: i});
    }
  }

  function _resetSnapshot(SnapshotGlobalVars storage _snapshotGlobalVars) internal {
    for (uint256 i = 0; i < baseAssets.length; ++i) {
      _resetAssetSnapshot(_snapshotGlobalVars.assetsInfo[baseAssets[i]], baseAssets[i]);
    }

    for (uint256 i = 0; i < NUMBER_OF_ACTORS; ++i) {
      _resetUserSnapshot(_snapshotGlobalVars.usersInfo[actorAddresses[i]]);
    }
    _resetUserSnapshot(_snapshotGlobalVars.usersInfo[UMBRELLA]);
    _resetUserSnapshot(_snapshotGlobalVars.usersInfo[address(contracts.treasury)]);

    for (uint256 i = 0; i < type(uint8).max; ++i) {
      _resetEModeSnapshot({_eModeSnapshot: _snapshotGlobalVars.eModesInfo[i]});
    }
  }

  function _makeEModeSnapshot(EModeInfo storage _eModeSnapshot, uint256 eModeCategory) internal {
    DataTypes.EModeCategoryLegacy memory eModeData = pool.getEModeCategoryData(
      // forge-lint: disable-next-line(unsafe-typecast)
      uint8(eModeCategory)
    );
    _eModeSnapshot.ltv = eModeData.ltv;
    _eModeSnapshot.liquidationThreshold = eModeData.liquidationThreshold;
    _eModeSnapshot.liquidationBonus = eModeData.liquidationBonus;

    // forge-lint: disable-next-line(unsafe-typecast)
    _eModeSnapshot.collateralBitmap = pool.getEModeCategoryCollateralBitmap(uint8(eModeCategory));
    // forge-lint: disable-next-line(unsafe-typecast)
    _eModeSnapshot.borrowableBitmap = pool.getEModeCategoryBorrowableBitmap(uint8(eModeCategory));
    // forge-lint: disable-next-line(unsafe-typecast)
    _eModeSnapshot.ltvzeroBitmap = pool.getEModeCategoryLtvzeroBitmap(uint8(eModeCategory));

    for (uint256 i = 0; i < baseAssets.length; ++i) {
      address asset = baseAssets[i];

      DataTypes.ReserveDataLegacy memory reserveData = pool.getReserveData(asset);

      if (
        EModeConfiguration.isReserveEnabledOnBitmap({
          bitmap: _eModeSnapshot.collateralBitmap,
          reserveIndex: reserveData.id
        })
      ) {
        _eModeSnapshot.isCollateral[asset] = true;
        _eModeSnapshot.collateralAssets.push(asset);
      }

      if (
        EModeConfiguration.isReserveEnabledOnBitmap({
          bitmap: _eModeSnapshot.borrowableBitmap,
          reserveIndex: reserveData.id
        })
      ) {
        _eModeSnapshot.isBorrowable[asset] = true;
        _eModeSnapshot.borrowableAssets.push(asset);
      }

      if (
        EModeConfiguration.isReserveEnabledOnBitmap({
          bitmap: _eModeSnapshot.ltvzeroBitmap,
          reserveIndex: reserveData.id
        })
      ) {
        _eModeSnapshot.isLtvZero[asset] = true;
        _eModeSnapshot.ltvZeroAssets.push(asset);
      }
    }

    _eModeSnapshot.isEnabled = _eModeSnapshot.collateralAssets.length > 0;
  }

  function _resetEModeSnapshot(EModeInfo storage _eModeSnapshot) internal {
    _eModeSnapshot.ltv = 0;
    _eModeSnapshot.liquidationThreshold = 0;
    _eModeSnapshot.liquidationBonus = 0;

    _eModeSnapshot.collateralBitmap = 0;
    _eModeSnapshot.borrowableBitmap = 0;
    _eModeSnapshot.ltvzeroBitmap = 0;

    for (uint256 i = 0; i < baseAssets.length; ++i) {
      address asset = baseAssets[i];

      _eModeSnapshot.isCollateral[asset] = false;
      _eModeSnapshot.isBorrowable[asset] = false;
      _eModeSnapshot.isLtvZero[asset] = false;

      for (uint256 j = 0; j < _eModeSnapshot.collateralAssets.length; ++i) {
        _eModeSnapshot.collateralAssets.pop();
      }
      for (uint256 j = 0; j < _eModeSnapshot.borrowableAssets.length; ++i) {
        _eModeSnapshot.borrowableAssets.pop();
      }
      for (uint256 j = 0; j < _eModeSnapshot.ltvZeroAssets.length; ++i) {
        _eModeSnapshot.ltvZeroAssets.pop();
      }
    }

    _eModeSnapshot.isEnabled = false;
  }

  function _makeAssetSnapshot(AssetInfo storage _assetSnapshot, address asset) internal {
    _assetSnapshot.underlyingTotalSupply = IERC20(asset).totalSupply();

    address aToken = protocolTokens[asset].aTokenAddress;
    _assetSnapshot.aTokenTotalSupply = IERC20(aToken).totalSupply();
    _assetSnapshot.aTokenRealTotalSupply = _getRealTotalSupply(asset);
    _assetSnapshot.aTokenScaledTotalSupply = IAToken(aToken).scaledTotalSupply();

    address vToken = protocolTokens[asset].variableDebtTokenAddress;
    _assetSnapshot.vTokenTotalSupply = IERC20(vToken).totalSupply();
    _assetSnapshot.vTokenScaledTotalSupply = IVariableDebtToken(vToken).scaledTotalSupply();

    _assetSnapshot.virtualUnderlyingBalance = pool.getVirtualUnderlyingBalance(asset);
    _assetSnapshot.accruedToTreasury = pool.getReserveData(asset).accruedToTreasury;
    _assetSnapshot.reserveDeficit = pool.getReserveDeficit(asset);
    _assetSnapshot.liquidationGracePeriodUntil = pool.getLiquidationGracePeriod(asset);

    _assetSnapshot.pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(asset);

    DataTypes.ReserveDataLegacy memory reserveData = pool.getReserveData(asset);
    _assetSnapshot.configuration = reserveData.configuration;
    _assetSnapshot.liquidityRate = reserveData.currentLiquidityRate;
    _assetSnapshot.variableBorrowRate = reserveData.currentVariableBorrowRate;

    _assetSnapshot.liquidityIndex = pool.getReserveNormalizedIncome(asset);
    _assetSnapshot.variableBorrowIndex = pool.getReserveNormalizedVariableDebt(asset);
  }

  function _resetAssetSnapshot(AssetInfo storage _assetSnapshot, address /* asset */) internal {
    _assetSnapshot.underlyingTotalSupply = 0;
    _assetSnapshot.aTokenTotalSupply = 0;
    _assetSnapshot.aTokenRealTotalSupply = 0;
    _assetSnapshot.aTokenScaledTotalSupply = 0;
    _assetSnapshot.vTokenTotalSupply = 0;
    _assetSnapshot.vTokenScaledTotalSupply = 0;
    _assetSnapshot.virtualUnderlyingBalance = 0;
    _assetSnapshot.accruedToTreasury = 0;
    _assetSnapshot.reserveDeficit = 0;
    _assetSnapshot.liquidationGracePeriodUntil = 0;
    _assetSnapshot.configuration = DataTypes.ReserveConfigurationMap(0);
    _assetSnapshot.liquidityRate = 0;
    _assetSnapshot.variableBorrowRate = 0;
    _assetSnapshot.liquidityIndex = 0;
    _assetSnapshot.variableBorrowIndex = 0;
  }

  function _makeUserSnapshot(UserInfo storage _userSnapshot, address user) internal {
    (
      _userSnapshot.totalCollateralBase,
      _userSnapshot.totalDebtBase,
      ,
      _userSnapshot.liquidationThreshold,
      _userSnapshot.ltv,
      _userSnapshot.healthFactor
    ) = pool.getUserAccountData(user);

    _userSnapshot.isHealthy = _isHealthy(_userSnapshot.healthFactor);

    _userSnapshot.userEModeCategory = pool.getUserEMode(user);

    for (uint256 i = 0; i < baseAssets.length; ++i) {
      _makeUserAssetSnapshot({
        _userAssetSnapshot: _userSnapshot.userAssetsInfo[baseAssets[i]],
        user: user,
        asset: baseAssets[i]
      });
    }
  }

  function _resetUserSnapshot(UserInfo storage _userSnapshot) internal {
    _userSnapshot.totalCollateralBase = 0;
    _userSnapshot.totalDebtBase = 0;
    _userSnapshot.liquidationThreshold = 0;
    _userSnapshot.ltv = 0;
    _userSnapshot.healthFactor = 0;
    _userSnapshot.isHealthy = false;
    _userSnapshot.userEModeCategory = 0;

    for (uint256 i = 0; i < baseAssets.length; i++) {
      _resetUserAssetSnapshot({_userAssetSnapshot: _userSnapshot.userAssetsInfo[baseAssets[i]]});
    }
  }

  function _makeUserAssetSnapshot(
    UserAssetInfo storage _userAssetSnapshot,
    address user,
    address asset
  ) internal {
    uint256 assetUnit = 10 ** IERC20Detailed(asset).decimals();
    uint256 assetPrice = contracts.aaveOracle.getAssetPrice(asset);

    _userAssetSnapshot.underlyingBalance = IERC20(asset).balanceOf(user);
    _userAssetSnapshot.aTokenBalance = IERC20(protocolTokens[asset].aTokenAddress).balanceOf(user);
    _userAssetSnapshot.aTokenBalanceInBaseCurrency =
      (assetPrice * _userAssetSnapshot.aTokenBalance) /
      assetUnit;
    _userAssetSnapshot.aTokenScaledBalance = IAToken(protocolTokens[asset].aTokenAddress)
      .scaledBalanceOf(user);
    _userAssetSnapshot.vTokenBalance = IERC20(protocolTokens[asset].variableDebtTokenAddress)
      .balanceOf(user);
    _userAssetSnapshot.vTokenBalanceInBaseCurrency =
      (assetPrice * _userAssetSnapshot.vTokenBalance) /
      assetUnit;
    _userAssetSnapshot.vTokenScaledBalance = IVariableDebtToken(
      protocolTokens[asset].variableDebtTokenAddress
    ).scaledBalanceOf(user);

    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(user);
    _userAssetSnapshot.isUsingAsCollateral = userConfig.isUsingAsCollateral(
      protocolTokens[asset].id
    );

    for (uint256 i = 0; i < NUMBER_OF_ACTORS; ++i) {
      _makeUserAssetAllowanceSnapshot({
        _userAssetSnapshot: _userAssetSnapshot,
        owner: user,
        recipient: actorAddresses[i],
        asset: asset
      });
    }
    _makeUserAssetAllowanceSnapshot({
      _userAssetSnapshot: _userAssetSnapshot,
      owner: user,
      recipient: UMBRELLA,
      asset: asset
    });
  }

  function _resetUserAssetSnapshot(UserAssetInfo storage _userAssetSnapshot) internal {
    _userAssetSnapshot.underlyingBalance = 0;
    _userAssetSnapshot.aTokenBalance = 0;
    _userAssetSnapshot.aTokenBalanceInBaseCurrency = 0;
    _userAssetSnapshot.aTokenScaledBalance = 0;
    _userAssetSnapshot.vTokenBalance = 0;
    _userAssetSnapshot.vTokenBalanceInBaseCurrency = 0;
    _userAssetSnapshot.vTokenScaledBalance = 0;
    _userAssetSnapshot.isUsingAsCollateral = false;

    for (uint256 i = 0; i < NUMBER_OF_ACTORS; ++i) {
      _resetUserAssetAllowanceSnapshot({
        _userAssetSnapshot: _userAssetSnapshot,
        recipient: actorAddresses[i]
      });
    }
    _resetUserAssetAllowanceSnapshot({_userAssetSnapshot: _userAssetSnapshot, recipient: UMBRELLA});
  }

  function _makeUserAssetAllowanceSnapshot(
    UserAssetInfo storage _userAssetSnapshot,
    address owner,
    address recipient,
    address asset
  ) internal {
    _userAssetSnapshot.underlyingAllowances[recipient] = IERC20(asset).allowance(owner, recipient);
    _userAssetSnapshot.aTokenAllowances[recipient] = IERC20(protocolTokens[asset].aTokenAddress)
      .allowance(owner, recipient);
    _userAssetSnapshot.borrowAllowances[recipient] = ICreditDelegationToken(
      protocolTokens[asset].variableDebtTokenAddress
    ).borrowAllowance(owner, recipient);
  }

  function _resetUserAssetAllowanceSnapshot(
    UserAssetInfo storage _userAssetSnapshot,
    address recipient
  ) internal {
    _userAssetSnapshot.underlyingAllowances[recipient] = 0;
    _userAssetSnapshot.aTokenAllowances[recipient] = 0;
    _userAssetSnapshot.borrowAllowances[recipient] = 0;
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                   POST CONDITIONS: BASE                                   //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_BASE_GPOST_A() internal {
    for (uint256 i; i < baseAssets.length; i++) {
      assertLe(
        snapshotGlobalVarsBefore.assetsInfo[baseAssets[i]].liquidityIndex,
        snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].liquidityIndex,
        BASE_GPOST_A
      );

      assertLe(
        snapshotGlobalVarsBefore.assetsInfo[baseAssets[i]].variableBorrowIndex,
        snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].variableBorrowIndex,
        BASE_GPOST_A
      );
    }
  }

  function assert_BASE_GPOST_BCD() internal {
    for (uint256 i; i < baseAssets.length; i++) {
      if (
        snapshotGlobalVarsBefore.assetsInfo[baseAssets[i]].variableBorrowIndex !=
        snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].variableBorrowIndex
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
        snapshotGlobalVarsBefore.assetsInfo[baseAssets[i]].virtualUnderlyingBalance !=
        snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].virtualUnderlyingBalance
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
        snapshotGlobalVarsBefore.assetsInfo[baseAssets[i]].liquidityIndex !=
        snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].liquidityIndex
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
    for (uint256 i = 0; i < baseAssets.length; ++i) {
      if (
        snapshotGlobalVarsBefore.assetsInfo[baseAssets[i]].aTokenRealTotalSupply <
        snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].aTokenRealTotalSupply
      ) {
        uint256 supplyCap = snapshotGlobalVarsAfter
          .assetsInfo[baseAssets[i]]
          .configuration
          .getSupplyCap();
        if (supplyCap == 0) {
          continue;
        }

        assertLe(
          snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].aTokenRealTotalSupply,
          supplyCap * 10 ** IERC20Detailed(baseAssets[i]).decimals(),
          LENDING_GPOST_C
        );
      }
    }
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                 POST CONDITIONS: BORROWING                                  //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_BORROWING_GPOST_H() internal {
    for (uint256 i = 0; i < baseAssets.length; ++i) {
      if (
        snapshotGlobalVarsBefore.assetsInfo[baseAssets[i]].vTokenTotalSupply <
        snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].vTokenTotalSupply
      ) {
        uint256 borrowCap = snapshotGlobalVarsAfter
          .assetsInfo[baseAssets[i]]
          .configuration
          .getBorrowCap();
        if (borrowCap == 0) {
          continue;
        }

        assertLe(
          snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].vTokenTotalSupply,
          borrowCap * 10 ** IERC20Detailed(baseAssets[i]).decimals(),
          BORROWING_GPOST_H
        );
      }
    }
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                POST CONDITIONS: HEALTH FACTOR                             //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_HF_GPOST_A(address user) internal {
    if (
      snapshotGlobalVarsAfter.usersInfo[user].healthFactor <
      snapshotGlobalVarsBefore.usersInfo[user].healthFactor
    ) {
      // if a user hf has decreased check that the function called is not in isNonDecreasingHfAction
      // and that the user is active

      assertFalse(isNonDecreasingHfAction[msg.sig], HF_GPOST_A);
    }
  }

  function assert_HF_GPOST_B(address user) internal {
    if (
      snapshotGlobalVarsAfter.usersInfo[user].healthFactor >
      snapshotGlobalVarsBefore.usersInfo[user].healthFactor
    ) {
      // if a user hf has increased check that the function called is not in isNonIncreasingHfAction
      // and that the user is active
      assertFalse(isNonIncreasingHfAction[msg.sig], HF_GPOST_B);
    }
  }

  function assert_HF_GPOST_C(address user) internal {
    if (
      snapshotGlobalVarsBefore.usersInfo[user].isHealthy &&
      !snapshotGlobalVarsAfter.usersInfo[user].isHealthy
    ) {
      assertTrue(msg.sig == IPoolHandler.configureReserveAsCollateral.selector, HF_GPOST_C);
    }
  }

  function assert_HF_GPOST_D(address user) internal {
    /// @dev this check makes sure the property is only checked against target actors in targetted functions
    if (_isActiveActor(user)) {
      if (!snapshotGlobalVarsAfter.usersInfo[user].isHealthy) {
        assertTrue(isHfUnsafeAfterAction[msg.sig], HF_GPOST_D);
      }
    }
  }

  function assert_HF_GPOST_E(address user) internal {
    /// @dev this check makes sure the property is only checked against target actors in targetted functions
    if (_isActiveActor(user)) {
      if (!snapshotGlobalVarsAfter.usersInfo[user].isHealthy) {
        assertTrue(isHfUnsafeBeforeAction[msg.sig], HF_GPOST_E);
      }
    }
  }

  /*/////////////////////////////////////////////////////////////////////////////////////////////
  //                                   POST CONDITIONS: DEFICIT                                //
  /////////////////////////////////////////////////////////////////////////////////////////////*/

  function assert_DM_GPOST_A() internal {
    for (uint256 i = 0; i < baseAssets.length; i++) {
      if (
        snapshotGlobalVarsBefore.assetsInfo[baseAssets[i]].reserveDeficit >
        snapshotGlobalVarsAfter.assetsInfo[baseAssets[i]].reserveDeficit
      ) {
        assertTrue(msg.sig == IPoolHandler.eliminateReserveDeficit.selector, DM_GPOST_A);
      }
    }
  }
}
