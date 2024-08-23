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

  event AssetEModeCategoryChanged(address indexed asset, uint8 categoryId, bool allowed);

  function setUp() public {
    initTestEnvironment();
  }

  function test_configureEmodeCategory() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit EModeCategoryAdded(ct.id, ct.ltv, ct.lt, ct.lb, address(0), ct.label);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);

    DataTypes.EModeCategory memory emodeConfig = contracts.poolProxy.getEModeCategoryData(ct.id);
    assertEq(emodeConfig.ltv, ct.ltv);
    assertEq(emodeConfig.liquidationThreshold, ct.lt);
    assertEq(emodeConfig.liquidationBonus, ct.lb);
    assertEq(emodeConfig.label, ct.label);
  }

  function test_updateEModeCategory() public {
    EModeCategoryInput memory ogCategory = _genCategoryOne();
    EModeCategoryInput memory updatedCategory = EModeCategoryInput(
      ogCategory.id,
      90_00,
      92_00,
      101_00,
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
      address(0),
      updatedCategory.label
    );

    contracts.poolConfiguratorProxy.setEModeCategory(
      ogCategory.id,
      updatedCategory.ltv,
      updatedCategory.lt,
      updatedCategory.lb,
      updatedCategory.label
    );

    DataTypes.EModeCategory memory emodeConfig = contracts.poolProxy.getEModeCategoryData(
      ogCategory.id
    );
    assertEq(emodeConfig.ltv, updatedCategory.ltv);
    assertEq(emodeConfig.liquidationThreshold, updatedCategory.lt);
    assertEq(emodeConfig.liquidationBonus, updatedCategory.lb);
    assertEq(emodeConfig.label, updatedCategory.label);
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

  function test_setAssetEModeCategory() public {
    EModeCategoryInput memory input = _genCategoryOne();
    test_configureEmodeCategory();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit AssetEModeCategoryChanged(tokenList.usdx, input.id, true);
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, input.id, true);
  }

  function test_updateAssetEModeCategory() public {
    EModeCategoryInput memory ct = _genCategoryTwo();
    test_setAssetEModeCategory();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit AssetEModeCategoryChanged(tokenList.usdx, ct.id, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, ct.id, true);
  }

  function test_removeEModeCategoryFromAsset() public {
    EModeCategoryInput memory prevCt = _genCategoryOne();
    test_setAssetEModeCategory();
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit AssetEModeCategoryChanged(tokenList.usdx, prevCt.id, false);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.usdx, prevCt.id, false);
  }
}
