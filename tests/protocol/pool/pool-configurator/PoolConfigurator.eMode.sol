// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {PercentageMath} from '../../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {ReserveConfiguration, DataTypes} from '../../../../src/contracts/protocol/pool/PoolConfigurator.sol';
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

  event EModeAssetCategoryChanged(address indexed asset, uint8 oldCategoryId, uint8 newCategoryId);

  function setUp() public {
    initTestEnvironment();
  }

  function test_configureEmodeCategory() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit EModeCategoryAdded(ct.id, ct.ltv, ct.lt, ct.lb, ct.oracle, ct.label);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.oracle,
      ct.label
    );

    DataTypes.EModeCategory memory emodeConfig = contracts.poolProxy.getEModeCategoryData(ct.id);
    assertEq(emodeConfig.ltv, ct.ltv);
    assertEq(emodeConfig.liquidationThreshold, ct.lt);
    assertEq(emodeConfig.liquidationBonus, ct.lb);
    assertEq(emodeConfig.priceSource, ct.oracle);
    assertEq(emodeConfig.label, ct.label);
  }

  function test_reverts_configureEmodeCategory_bad_ltv() public {
    DataTypes.ReserveConfigurationMap memory currentConfig = contracts.poolProxy.getConfiguration(
      tokenList.wbtc
    );

    EModeCategoryInput memory ct = _genCategoryOne();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.oracle,
      ct.label
    );
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.wbtc, ct.id);

    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      uint16(currentConfig.getLtv() - 1),
      uint16(currentConfig.getLiquidationThreshold() + 1),
      ct.lb,
      ct.oracle,
      ct.label
    );
    vm.stopPrank();
  }

  function test_reverts_configureEmodeCategory_bad_lq() public {
    DataTypes.ReserveConfigurationMap memory currentConfig = contracts.poolProxy.getConfiguration(
      tokenList.wbtc
    );

    EModeCategoryInput memory ct = _genCategoryOne();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.oracle,
      ct.label
    );
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.wbtc, ct.id);

    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      uint16(currentConfig.getLtv() + 1),
      uint16(currentConfig.getLiquidationThreshold() - 1),
      ct.lb,
      ct.oracle,
      ct.label
    );
    vm.stopPrank();
  }

  function test_updateEModeCategory() public {
    EModeCategoryInput memory ogCategory = _genCategoryOne();
    EModeCategoryInput memory updatedCategory = EModeCategoryInput(
      ogCategory.id,
      90_00,
      92_00,
      101_00,
      makeAddr('EMODE_ORACLE'),
      'GROUP_B'
    );

    test_configureEmodeCategory();

    vm.prank(poolAdmin);
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit EModeCategoryAdded(
      ogCategory.id,
      updatedCategory.ltv,
      updatedCategory.lt,
      updatedCategory.lb,
      updatedCategory.oracle,
      updatedCategory.label
    );

    contracts.poolConfiguratorProxy.setEModeCategory(
      ogCategory.id,
      updatedCategory.ltv,
      updatedCategory.lt,
      updatedCategory.lb,
      updatedCategory.oracle,
      updatedCategory.label
    );

    DataTypes.EModeCategory memory emodeConfig = contracts.poolProxy.getEModeCategoryData(
      ogCategory.id
    );
    assertEq(emodeConfig.ltv, updatedCategory.ltv);
    assertEq(emodeConfig.liquidationThreshold, updatedCategory.lt);
    assertEq(emodeConfig.liquidationBonus, updatedCategory.lb);
    assertEq(emodeConfig.priceSource, updatedCategory.oracle);
    assertEq(emodeConfig.label, updatedCategory.label);
  }

  function test_reverts_setEmodeCategory_zero_ltv() public {
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 0, 80_00, 105_00, address(0), 'LABEL');
  }

  function test_reverts_setEmodeCategory_zero_liqThreshold() public {
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 80_00, 0, 105_00, address(0), 'LABEL');
  }

  function test_reverts_setEmodeCategory_ltv_gt_liqThreshold() public {
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 80_00, 79_00, 105_00, address(0), 'LABEL');
  }

  function test_reverts_setEmodeCategory_lb_lte_percentageFactor() public {
    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 80_00, 81_00, 100_00, address(0), 'LABEL');

    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 80_00, 81_00, 99_00, address(0), 'LABEL');
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
      address(0),
      'LABEL'
    );
  }

  function test_reverts_configureEmodeCategory_input_ltv_lt_reserve_emode_ltv() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.startPrank(poolAdmin);

    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.oracle,
      ct.label
    );
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, ct.id);

    (, uint256 ltv, , , , , , , , ) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );

    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      uint16(ltv) - 1,
      ct.lt,
      ct.lb,
      ct.oracle,
      ct.label
    );
    vm.stopPrank();
  }

  function test_reverts_configureEmodeCategory_input_lt_lt_reserve_emode_lt() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.oracle,
      ct.label
    );
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, ct.id);

    (, , uint256 lt, , , , , , , ) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );

    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_PARAMS));
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      uint16(lt) - 1,
      ct.lb,
      ct.oracle,
      ct.label
    );
    vm.stopPrank();
  }

  function test_setAssetEModeCategory() public {
    EModeCategoryInput memory input = _genCategoryOne();
    test_configureEmodeCategory();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit EModeAssetCategoryChanged(tokenList.usdx, 0, input.id);
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, input.id);
  }

  function test_updateAssetEModeCategory() public {
    EModeCategoryInput memory prevCt = _genCategoryOne();
    EModeCategoryInput memory ct = _genCategoryTwo();
    test_setAssetEModeCategory();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.oracle,
      ct.label
    );

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit EModeAssetCategoryChanged(tokenList.usdx, prevCt.id, ct.id);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, ct.id);
  }

  function test_removeEModeCategoryFromAsset() public {
    EModeCategoryInput memory prevCt = _genCategoryOne();
    test_setAssetEModeCategory();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit EModeAssetCategoryChanged(tokenList.usdx, prevCt.id, 0);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, 0);
  }

  function test_reverts_setAssetEModeCategory_invalid() public {
    EModeCategoryInput memory ct = _genCategoryOne();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      50_00,
      51_00,
      ct.lb,
      ct.oracle,
      ct.label
    );

    vm.expectRevert(bytes(Errors.INVALID_EMODE_CATEGORY_ASSIGNMENT));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, ct.id);
  }
}
