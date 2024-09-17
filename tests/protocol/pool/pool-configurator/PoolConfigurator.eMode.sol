// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {PercentageMath} from '../../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {ReserveConfiguration, DataTypes} from '../../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {EModeConfiguration} from '../../../../src/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {TestnetProcedures} from '../../../utils/TestnetProcedures.sol';

contract PoolConfiguratorEModeConfigTests is TestnetProcedures {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  event EModeCategoryAdded(
    uint8 indexed categoryId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    address oracle,
    string label
  );

  event AssetCollateralInEModeChanged(address indexed asset, uint8 categoryId, bool allowed);
  event AssetBorrowableInEModeChanged(address indexed asset, uint8 categoryId, bool borrowable);

  function setUp() public {
    initTestEnvironment();
  }

  function test_configureEmodeCategory() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit EModeCategoryAdded(ct.id, ct.ltv, ct.lt, ct.lb, address(0), ct.label);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);

    DataTypes.EModeCategory memory emodeConfig = _getFullEMode(ct.id);
    assertEq(emodeConfig.ltv, ct.ltv);
    assertEq(emodeConfig.liquidationThreshold, ct.lt);
    assertEq(emodeConfig.liquidationBonus, ct.lb);
    assertEq(emodeConfig.label, ct.label);
    assertEq(emodeConfig.collateralBitmap, 0);
    assertEq(emodeConfig.borrowableBitmap, 0);
  }

  function test_updateEModeCategory() public {
    test_configureEmodeCategory();
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, 1, true);
    DataTypes.EModeCategory memory ogCategory = _getFullEMode(ct.id);
    EModeCategoryInput memory updatedCategory = EModeCategoryInput(
      ct.id,
      90_00,
      92_00,
      101_00,
      'GROUP_B'
    );

    vm.prank(poolAdmin);
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit EModeCategoryAdded(
      ct.id,
      updatedCategory.ltv,
      updatedCategory.lt,
      updatedCategory.lb,
      address(0),
      updatedCategory.label
    );

    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      updatedCategory.ltv,
      updatedCategory.lt,
      updatedCategory.lb,
      updatedCategory.label
    );

    DataTypes.EModeCategory memory emodeConfig = _getFullEMode(ct.id);
    assertEq(emodeConfig.ltv, updatedCategory.ltv);
    assertEq(emodeConfig.liquidationThreshold, updatedCategory.lt);
    assertEq(emodeConfig.liquidationBonus, updatedCategory.lb);
    assertEq(emodeConfig.label, updatedCategory.label);
    assertEq(emodeConfig.collateralBitmap, ogCategory.collateralBitmap);
    assertEq(emodeConfig.borrowableBitmap, ogCategory.borrowableBitmap);
  }

  function test_reverts_setEmodeCategory_zero_ltv() public {
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 0, 80_00, 105_00, 'LABEL');
  }

  function test_reverts_setEmodeCategory_zero_liqThreshold() public {
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 80_00, 0, 105_00, 'LABEL');
  }

  function test_reverts_setEmodeCategory_ltv_gt_liqThreshold() public {
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 80_00, 79_00, 105_00, 'LABEL');
  }

  function test_reverts_setEmodeCategory_lb_lte_percentageFactor() public {
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 80_00, 81_00, 100_00, 'LABEL');

    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 80_00, 81_00, 99_00, 'LABEL');
  }

  function test_reverts_setEmodeCategory_liquidation_threshold_doesnt_match_bonus() public {
    uint16 liquidationThreshold = 98_00;
    uint16 liquidationBonus = 120_00;
    uint256 isBonusNotCovered = uint256(liquidationThreshold).percentMul(liquidationBonus);
    assertGt(
      isBonusNotCovered,
      PercentageMath.PERCENTAGE_FACTOR,
      'Input should be gt than percentage factor to revert at "threshold * bonus is required to be less than PERCENTAGE_FACTOR"'
    );
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      1,
      90_00,
      liquidationThreshold,
      liquidationBonus,
      'LABEL'
    );
  }

  function test_setAssetCollateralInEMode() public {
    EModeCategoryInput memory input = _genCategoryOne();
    test_configureEmodeCategory();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit AssetCollateralInEModeChanged(tokenList.usdx, input.id, true);
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, input.id, true);
    DataTypes.EModeCategory memory config = _getFullEMode(input.id);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(config.collateralBitmap, reserveData.id),
      true
    );
  }

  function test_addAnotherAssetCollateralInEMode() public {
    EModeCategoryInput memory input = _genCategoryOne();
    test_setAssetCollateralInEMode();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, input.id, true);
    DataTypes.EModeCategory memory config = _getFullEMode(input.id);
    DataTypes.ReserveDataLegacy memory reserveDataUSDX = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    DataTypes.ReserveDataLegacy memory reserveDataWBTC = contracts.poolProxy.getReserveData(
      tokenList.wbtc
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(config.collateralBitmap, reserveDataUSDX.id),
      true
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(config.collateralBitmap, reserveDataWBTC.id),
      true
    );
  }

  function test_removeCollateralFromEmode() public {
    EModeCategoryInput memory prevCt = _genCategoryOne();
    test_setAssetCollateralInEMode();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit AssetCollateralInEModeChanged(tokenList.usdx, prevCt.id, false);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, prevCt.id, false);

    DataTypes.EModeCategory memory config = _getFullEMode(prevCt.id);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(config.collateralBitmap, reserveData.id),
      false
    );
  }

  function test_setAssetBorrowableInEMode() public {
    EModeCategoryInput memory input = _genCategoryOne();
    test_configureEmodeCategory();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit AssetBorrowableInEModeChanged(tokenList.usdx, input.id, true);
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, input.id, true);
    DataTypes.EModeCategory memory config = _getFullEMode(input.id);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(config.borrowableBitmap, reserveData.id),
      true
    );
  }

  function test_addAnotherAssetBorrowableInEMode() public {
    EModeCategoryInput memory input = _genCategoryOne();
    test_setAssetBorrowableInEMode();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, input.id, true);
    DataTypes.EModeCategory memory config = _getFullEMode(input.id);
    DataTypes.ReserveDataLegacy memory reserveDataUSDX = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    DataTypes.ReserveDataLegacy memory reserveDataWBTC = contracts.poolProxy.getReserveData(
      tokenList.wbtc
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(config.borrowableBitmap, reserveDataUSDX.id),
      true
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(config.borrowableBitmap, reserveDataWBTC.id),
      true
    );
  }

  function test_removeBorrowableFromEmode() public {
    EModeCategoryInput memory input = _genCategoryOne();
    test_configureEmodeCategory();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit AssetBorrowableInEModeChanged(tokenList.usdx, input.id, false);
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, input.id, false);
    DataTypes.EModeCategory memory config = _getFullEMode(input.id);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(config.borrowableBitmap, reserveData.id),
      false
    );
  }

  function _getFullEMode(uint8 eMode) internal view returns (DataTypes.EModeCategory memory) {
    DataTypes.EModeCategory memory eModeCategory;
    DataTypes.CollateralConfig memory cfg = contracts.poolProxy.getEModeCategoryCollateralConfig(
      eMode
    );
    eModeCategory.ltv = cfg.ltv;
    eModeCategory.liquidationThreshold = cfg.liquidationThreshold;
    eModeCategory.liquidationBonus = cfg.liquidationBonus;
    (eModeCategory.label) = contracts.poolProxy.getEModeCategoryLabel(eMode);
    (eModeCategory.collateralBitmap) = contracts.poolProxy.getEModeCategoryCollateralBitmap(eMode);
    (eModeCategory.borrowableBitmap) = contracts.poolProxy.getEModeCategoryBorrowableBitmap(eMode);
    return eModeCategory;
  }
}
