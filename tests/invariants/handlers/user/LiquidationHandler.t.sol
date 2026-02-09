// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';
import {PercentageMath} from 'src/contracts/protocol/libraries/math/PercentageMath.sol';
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';

// Libraries
import 'forge-std/console2.sol';

// Test Contracts
import {Actor} from '../../utils/Actor.sol';
import {BaseHandler} from '../../base/BaseHandler.t.sol';

/// @title LiquidationHandler
/// @notice Handler test contract for a set of actions
contract LiquidationHandler is BaseHandler {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function liquidationCall(
    uint256 debtToCover,
    bool receiveAToken,
    uint8 i,
    uint8 j,
    uint8 k
  ) external setup {
    bool success;
    bytes memory returnData;

    address borrower = _getRandomActor(i);
    _setReceiverActor(borrower);
    // users cannot liquidate themselfes
    if (borrower == address(actor)) {
      borrower = _getRandomActor(i + 1);
    }
    require(borrower != address(actor));

    address collateralAsset = _getRandomBaseAsset(j);
    address debtAsset = _getRandomBaseAsset(k);

    _before();
    {
      bytes memory callData = abi.encodeWithSelector(
        IPool.liquidationCall.selector,
        collateralAsset,
        debtAsset,
        borrower,
        debtToCover,
        receiveAToken
      );
      (success, returnData) = actor.proxy(address(pool), callData);
    }

    if (
      snapshotGlobalVarsBefore.assetsInfo[collateralAsset].liquidationGracePeriodUntil >=
      block.timestamp ||
      snapshotGlobalVarsBefore.assetsInfo[debtAsset].liquidationGracePeriodUntil >= block.timestamp
    ) {
      assertFalse(success, LIQUIDATION_HSPOST_B);
    }

    if (success) {
      _after();

      // POST-CONDITIONS
      assertFalse(snapshotGlobalVarsBefore.usersInfo[borrower].isHealthy, LIQUIDATION_HSPOST_A);

      uint256 additionalDeficit = snapshotGlobalVarsAfter.assetsInfo[debtAsset].reserveDeficit -
        snapshotGlobalVarsBefore.assetsInfo[debtAsset].reserveDeficit;
      if (additionalDeficit > 0) {
        assertEq(
          snapshotGlobalVarsAfter.usersInfo[borrower].totalCollateralBase,
          0,
          LIQUIDATION_HSPOST_L
        );
        assertEq(
          snapshotGlobalVarsAfter.usersInfo[borrower].userAssetsInfo[debtAsset].vTokenBalance,
          0,
          LIQUIDATION_HSPOST_M
        );
        assertLe(
          additionalDeficit,
          snapshotGlobalVarsBefore.usersInfo[borrower].userAssetsInfo[debtAsset].vTokenBalance,
          LIQUIDATION_HSPOST_N
        );
      }

      uint256 liquidatedDebtAmount = snapshotGlobalVarsBefore
        .usersInfo[borrower]
        .userAssetsInfo[debtAsset]
        .vTokenBalance -
        snapshotGlobalVarsAfter.usersInfo[borrower].userAssetsInfo[debtAsset].vTokenBalance;

      uint256 liquidatedCollateralAmount = snapshotGlobalVarsBefore
        .usersInfo[borrower]
        .userAssetsInfo[collateralAsset]
        .aTokenBalance -
        snapshotGlobalVarsAfter.usersInfo[borrower].userAssetsInfo[collateralAsset].aTokenBalance;
      uint256 protocolFeeAmount = snapshotGlobalVarsAfter
        .usersInfo[address(contracts.treasury)]
        .userAssetsInfo[collateralAsset]
        .aTokenBalance -
        snapshotGlobalVarsBefore
          .usersInfo[address(contracts.treasury)]
          .userAssetsInfo[collateralAsset]
          .aTokenBalance;
      liquidatedCollateralAmount -= protocolFeeAmount;

      if (receiveAToken) {
        assertApproxEqAbs(
          snapshotGlobalVarsAfter
            .usersInfo[address(actor)]
            .userAssetsInfo[collateralAsset]
            .aTokenBalance,
          snapshotGlobalVarsBefore
            .usersInfo[address(actor)]
            .userAssetsInfo[collateralAsset]
            .aTokenBalance + liquidatedCollateralAmount,
          8,
          LIQUIDATION_HSPOST_P
        );
      } else {
        assertApproxEqAbs(
          snapshotGlobalVarsAfter
            .usersInfo[address(actor)]
            .userAssetsInfo[collateralAsset]
            .underlyingBalance,
          snapshotGlobalVarsBefore
            .usersInfo[address(actor)]
            .userAssetsInfo[collateralAsset]
            .underlyingBalance + liquidatedCollateralAmount,
          8,
          LIQUIDATION_HSPOST_P
        );
      }

      assertApproxEqAbs(
        snapshotGlobalVarsBefore
          .usersInfo[address(actor)]
          .userAssetsInfo[debtAsset]
          .underlyingBalance,
        snapshotGlobalVarsAfter
          .usersInfo[address(actor)]
          .userAssetsInfo[debtAsset]
          .underlyingBalance + liquidatedDebtAmount,
        4,
        LIQUIDATION_HSPOST_Q
      );

      assertApproxEqAbs(
        snapshotGlobalVarsAfter.assetsInfo[debtAsset].virtualUnderlyingBalance,
        snapshotGlobalVarsBefore.assetsInfo[debtAsset].virtualUnderlyingBalance +
          liquidatedDebtAmount,
        4,
        LIQUIDATION_HSPOST_R
      );
      assertApproxEqAbs(
        snapshotGlobalVarsBefore.assetsInfo[collateralAsset].virtualUnderlyingBalance,
        snapshotGlobalVarsAfter.assetsInfo[collateralAsset].virtualUnderlyingBalance +
          liquidatedDebtAmount,
        4,
        LIQUIDATION_HSPOST_S
      );
    } else {
      revert('LiquidationHandler: liquidate action reverted');
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
