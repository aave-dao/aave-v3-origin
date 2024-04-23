// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AToken} from 'aave-v3-core/contracts/protocol/tokenization/AToken.sol';
import {Errors} from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetERC20} from 'aave-v3-periphery/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {ConfiguratorInputTypes} from 'aave-v3-core/contracts/protocol/pool/PoolConfigurator.sol';
import {IDefaultInterestRateStrategyV2} from 'aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategyV2.sol';
import {TestnetProcedures, TestVars, TestReserveConfig} from '../utils/TestnetProcedures.sol';

contract PoolConfiguratorInitReservesTest is TestnetProcedures {
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  function setUp() public {
    initTestEnvironment();
  }

  function test_initReserves_singleAsset(bool isVirtualAccActive) public {
    TestnetERC20 newToken = new TestnetERC20('Misc Token', 'MISC', 18, poolAdmin);

    TestVars memory t;
    t.aTokenName = 'Misc AToken';
    t.aTokenSymbol = 'aMISC';
    t.variableDebtName = 'Variable Debt Misc';
    t.variableDebtSymbol = 'varDebtMISC';
    t.rateStrategy = report.defaultInterestRateStrategyV2;
    t.interestRateData = abi.encode(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: 80_00,
        baseVariableBorrowRate: 1_00,
        variableRateSlope1: 4_00,
        variableRateSlope2: 60_00
      })
    );
    uint256 previousListedAssets = contracts.poolProxy.getReservesList().length;

    ConfiguratorInputTypes.InitReserveInput[]
      memory input = new ConfiguratorInputTypes.InitReserveInput[](1);

    input[0] = ConfiguratorInputTypes.InitReserveInput(
      report.aToken,
      report.variableDebtToken,
      newToken.decimals(),
      isVirtualAccActive,
      t.rateStrategy,
      address(newToken),
      report.treasury,
      report.rewardsControllerProxy,
      t.aTokenName,
      t.aTokenSymbol,
      t.variableDebtName,
      t.variableDebtSymbol,
      t.emptyParams,
      t.interestRateData
    );
    vm.expectEmit(true, false, false, false, address(contracts.poolConfiguratorProxy));
    emit ReserveInitialized(
      input[0].underlyingAsset,
      address(0),
      address(0),
      address(0),
      input[0].interestRateStrategyAddress
    );

    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    // Perform assertions
    {
      (address aTokenProxy, , address variableDebtProxy) = contracts
        .protocolDataProvider
        .getReserveTokensAddresses(address(newToken));

      assertEq(AToken(aTokenProxy).name(), t.aTokenName);
      assertEq(AToken(aTokenProxy).symbol(), t.aTokenSymbol);
      assertEq(AToken(aTokenProxy).decimals(), newToken.decimals());
      assertEq(AToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(), report.treasury);
      assertEq(AToken(aTokenProxy).UNDERLYING_ASSET_ADDRESS(), address(newToken));
      assertEq(
        address(AToken(aTokenProxy).getIncentivesController()),
        report.rewardsControllerProxy
      );

      assertEq(AToken(variableDebtProxy).name(), t.variableDebtName);
      assertEq(AToken(variableDebtProxy).symbol(), t.variableDebtSymbol);
      assertEq(AToken(variableDebtProxy).decimals(), newToken.decimals());
      assertEq(AToken(variableDebtProxy).UNDERLYING_ASSET_ADDRESS(), address(newToken));
      assertEq(
        address(AToken(variableDebtProxy).getIncentivesController()),
        report.rewardsControllerProxy
      );
    }
    // Perform default asset checks
    TestReserveConfig memory c = _getReserveConfig(address(newToken), report.protocolDataProvider);

    assertEq(c.isActive, true);
    assertEq(c.isFrozen, false);
    assertEq(c.isPaused, false);
    assertEq(c.decimals, newToken.decimals());

    assertEq(c.ltv, 0);
    assertEq(c.liquidationThreshold, 0);
    assertEq(c.liquidationBonus, 0);
    assertEq(c.reserveFactor, 0);
    assertEq(c.usageAsCollateralEnabled, false);
    assertEq(c.borrowingEnabled, false);
    assertEq(c.isVirtualAccActive, isVirtualAccActive);

    assertEq(contracts.poolProxy.getReservesList().length, previousListedAssets + 1);
  }

  function test_initReserves_multipleAssets() public {
    ConfiguratorInputTypes.InitReserveInput[] memory input = _generateListingInput(
      4,
      report,
      poolAdmin
    );
    uint256 previousListedAssets = contracts.poolProxy.getReservesList().length;

    for (uint256 y; y < input.length; ++y) {
      vm.expectEmit(true, false, false, false, address(contracts.poolConfiguratorProxy));
      emit ReserveInitialized(
        input[y].underlyingAsset,
        address(0),
        address(0),
        address(0),
        input[y].interestRateStrategyAddress
      );
    }

    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    // Perform assertions
    for (uint256 y; y < input.length; ++y) {
      ConfiguratorInputTypes.InitReserveInput memory reserveInput = input[y];

      {
        (address aTokenProxy, , address variableDebtProxy) = contracts
          .protocolDataProvider
          .getReserveTokensAddresses(reserveInput.underlyingAsset);

        assertEq(AToken(aTokenProxy).name(), reserveInput.aTokenName);
        assertEq(AToken(aTokenProxy).symbol(), reserveInput.aTokenSymbol);
        assertEq(AToken(aTokenProxy).decimals(), reserveInput.underlyingAssetDecimals);
        assertEq(AToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(), reserveInput.treasury);
        assertEq(AToken(aTokenProxy).UNDERLYING_ASSET_ADDRESS(), reserveInput.underlyingAsset);
        assertEq(
          address(AToken(aTokenProxy).getIncentivesController()),
          reserveInput.incentivesController
        );

        assertEq(AToken(variableDebtProxy).name(), reserveInput.variableDebtTokenName);
        assertEq(AToken(variableDebtProxy).symbol(), reserveInput.variableDebtTokenSymbol);
        assertEq(AToken(variableDebtProxy).decimals(), reserveInput.underlyingAssetDecimals);
        assertEq(
          AToken(variableDebtProxy).UNDERLYING_ASSET_ADDRESS(),
          reserveInput.underlyingAsset
        );
        assertEq(
          address(AToken(variableDebtProxy).getIncentivesController()),
          reserveInput.incentivesController
        );
      }
      // Perform default asset checks
      TestReserveConfig memory c = _getReserveConfig(
        reserveInput.underlyingAsset,
        report.protocolDataProvider
      );

      assertEq(c.isActive, true);
      assertEq(c.isFrozen, false);
      assertEq(c.isPaused, false);
      assertEq(c.decimals, reserveInput.underlyingAssetDecimals);

      assertEq(c.ltv, 0);
      assertEq(c.liquidationThreshold, 0);
      assertEq(c.liquidationBonus, 0);
      assertEq(c.reserveFactor, 0);
      assertEq(c.usageAsCollateralEnabled, false);
      assertEq(c.borrowingEnabled, false);
    }
    assertEq(contracts.poolProxy.getReservesList().length, previousListedAssets + input.length);
  }

  function test_initReserves_zeroAssets() public {
    uint256 previousListedAssets = contracts.poolProxy.getReservesList().length;

    ConfiguratorInputTypes.InitReserveInput[] memory input;

    // Perform action, does not revert but does nothing due empty array, no-op
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    assertEq(contracts.poolProxy.getReservesList().length, previousListedAssets);
  }

  function test_reverts_initReserves_maxAssets() public {
    uint256 previousListedAssets = contracts.poolProxy.getReservesList().length;
    uint256 maxListings = contracts.poolProxy.MAX_NUMBER_RESERVES() - previousListedAssets + 1;
    ConfiguratorInputTypes.InitReserveInput[] memory input = _generateListingInput(
      maxListings,
      report,
      poolAdmin
    );

    vm.expectRevert(bytes(Errors.NO_MORE_RESERVES_ALLOWED));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    assertEq(contracts.poolProxy.getReservesList().length, previousListedAssets);
  }

  function test_initReserves_notEnoughDecimal(uint8 decimals) public {
    vm.assume(decimals < 6);
    TestnetERC20 newToken = new TestnetERC20('Misc Token', 'MISC', decimals, poolAdmin);

    TestVars memory t;
    t.aTokenName = 'Misc AToken';
    t.aTokenSymbol = 'aMISC';
    t.variableDebtName = 'Variable Debt Misc';
    t.variableDebtSymbol = 'varDebtMISC';
    t.rateStrategy = report.defaultInterestRateStrategyV2;
    t.interestRateData = abi.encode(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: 80_00,
        baseVariableBorrowRate: 1_00,
        variableRateSlope1: 4_00,
        variableRateSlope2: 60_00
      })
    );

    ConfiguratorInputTypes.InitReserveInput[]
      memory input = new ConfiguratorInputTypes.InitReserveInput[](1);

    input[0] = ConfiguratorInputTypes.InitReserveInput(
      report.aToken,
      report.variableDebtToken,
      newToken.decimals(),
      true,
      t.rateStrategy,
      address(newToken),
      report.treasury,
      report.rewardsControllerProxy,
      t.aTokenName,
      t.aTokenSymbol,
      t.variableDebtName,
      t.variableDebtSymbol,
      t.emptyParams,
      t.interestRateData
    );

    vm.expectRevert(bytes(Errors.INVALID_DECIMALS));

    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);
  }
}
