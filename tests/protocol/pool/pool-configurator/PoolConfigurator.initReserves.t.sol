// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AToken} from '../../../../src/contracts/protocol/tokenization/AToken.sol';
import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetERC20} from '../../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {ConfiguratorInputTypes} from '../../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {IDefaultInterestRateStrategyV2} from '../../../../src/contracts/misc/DefaultReserveInterestRateStrategyV2.sol';
import {TestnetProcedures, TestVars, TestReserveConfig} from '../../../utils/TestnetProcedures.sol';

contract PoolConfiguratorInitReservesTest is TestnetProcedures {
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  function setUp() public {
    initTestEnvironment(false);
  }

  function test_initReserves_validNumberOfAssets(TestVars[128] memory t, uint8 length) public {
    vm.assume(length > 0 && length < 128);

    uint256 previousListedAssets = contracts.poolProxy.getReservesList().length;
    uint256 maxListings = contracts.poolProxy.MAX_NUMBER_RESERVES() - previousListedAssets + 1;
    vm.assume(length < maxListings);

    ConfiguratorInputTypes.InitReserveInput[]
      memory input = new ConfiguratorInputTypes.InitReserveInput[](length);
    for (uint256 i = 0; i < length; i++) {
      input[i] = _generateInitReserveInput(t[i], report, poolAdmin, true);

      vm.expectEmit(true, false, false, false, address(contracts.poolConfiguratorProxy));
      emit ReserveInitialized(
        input[i].underlyingAsset,
        address(0),
        address(0),
        address(0),
        input[i].interestRateStrategyAddress
      );
    }
    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    for (uint256 i = 0; i < length; i++) {
      ConfiguratorInputTypes.InitReserveInput memory initConfig = input[i];
      // Perform assertions
      {
        (address aTokenProxy, , address variableDebtProxy) = contracts
          .protocolDataProvider
          .getReserveTokensAddresses(initConfig.underlyingAsset);

        assertEq(AToken(aTokenProxy).name(), initConfig.aTokenName);
        assertEq(AToken(aTokenProxy).symbol(), initConfig.aTokenSymbol);
        assertEq(
          AToken(aTokenProxy).decimals(),
          TestnetERC20(initConfig.underlyingAsset).decimals()
        );
        assertEq(AToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(), initConfig.treasury);
        assertEq(AToken(aTokenProxy).UNDERLYING_ASSET_ADDRESS(), initConfig.underlyingAsset);
        assertEq(
          address(AToken(aTokenProxy).getIncentivesController()),
          initConfig.incentivesController
        );

        assertEq(AToken(variableDebtProxy).name(), initConfig.variableDebtTokenName);
        assertEq(AToken(variableDebtProxy).symbol(), initConfig.variableDebtTokenSymbol);
        assertEq(
          AToken(variableDebtProxy).decimals(),
          TestnetERC20(initConfig.underlyingAsset).decimals()
        );
        assertEq(AToken(variableDebtProxy).UNDERLYING_ASSET_ADDRESS(), initConfig.underlyingAsset);
        assertEq(
          address(AToken(variableDebtProxy).getIncentivesController()),
          initConfig.incentivesController
        );
      }
      // Perform default asset checks
      TestReserveConfig memory c = _getReserveConfig(
        initConfig.underlyingAsset,
        report.protocolDataProvider
      );

      assertEq(c.isActive, true);
      assertEq(c.isFrozen, false);
      assertEq(c.isPaused, false);
      assertEq(c.decimals, TestnetERC20(initConfig.underlyingAsset).decimals());

      assertEq(c.ltv, 0);
      assertEq(c.liquidationThreshold, 0);
      assertEq(c.liquidationBonus, 0);
      assertEq(c.reserveFactor, 0);
      assertEq(c.usageAsCollateralEnabled, false);
      assertEq(c.borrowingEnabled, false);
      assertEq(c.isVirtualAccActive, initConfig.useVirtualBalance);
    }
    assertEq(contracts.poolProxy.getReservesList().length, previousListedAssets + length);
  }

  function test_initReserves_zeroAssets() public {
    uint256 previousListedAssets = contracts.poolProxy.getReservesList().length;

    ConfiguratorInputTypes.InitReserveInput[] memory input;

    // Perform action, does not revert but does nothing due empty array, no-op
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    assertEq(contracts.poolProxy.getReservesList().length, previousListedAssets);
  }

  function test_reverts_initReserves_maxAssets(TestVars memory t, uint8 lengthSeed) public {
    uint256 previousListedAssets = contracts.poolProxy.getReservesList().length;

    uint256 maxListings = contracts.poolProxy.MAX_NUMBER_RESERVES() - previousListedAssets + 1;
    uint256 length = maxListings + lengthSeed;

    ConfiguratorInputTypes.InitReserveInput[]
      memory input = new ConfiguratorInputTypes.InitReserveInput[](length);
    for (uint256 i = 0; i < length; i++)
      input[i] = _generateInitReserveInput(t, report, poolAdmin, true);

    vm.expectRevert(bytes(Errors.NO_MORE_RESERVES_ALLOWED));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    assertEq(contracts.poolProxy.getReservesList().length, previousListedAssets);
  }

  function test_initReserves_notEnoughDecimal(TestVars memory t) public {
    t.underlyingDecimals = uint8(bound(t.underlyingDecimals, 0, 5));

    ConfiguratorInputTypes.InitReserveInput[] memory input = _generateInitConfig(
      t,
      report,
      poolAdmin,
      false
    );

    vm.expectRevert(bytes(Errors.INVALID_DECIMALS));

    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);
  }
}
