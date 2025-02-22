// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {DeployUtils} from '../../src/deployments/contracts/utilities/DeployUtils.sol';
import {FfiUtils} from '../../src/deployments/contracts/utilities/FfiUtils.sol';
import {DefaultMarketInput} from '../../src/deployments/inputs/DefaultMarketInput.sol';
import {AaveV3BatchOrchestration} from '../../src/deployments/projects/aave-v3-batched/AaveV3BatchOrchestration.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {AaveV3TestListing} from '../mocks/AaveV3TestListing.sol';
import {ACLManager, Errors} from '../../src/contracts/protocol/configuration/ACLManager.sol';
import {WETH9} from '../../src/contracts/dependencies/weth/WETH9.sol';
import {TestnetERC20} from '../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {PoolConfigurator} from '../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {DefaultReserveInterestRateStrategyV2} from '../../src/contracts/misc/DefaultReserveInterestRateStrategyV2.sol';
import {ReserveConfiguration} from '../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {PercentageMath} from '../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {AaveProtocolDataProvider} from '../../src/contracts/helpers/AaveProtocolDataProvider.sol';
import {MarketReportUtils} from '../../src/deployments/contracts/utilities/MarketReportUtils.sol';
import {AaveV3ConfigEngine, IAaveV3ConfigEngine} from '../../src/contracts/extensions/v3-config-engine/AaveV3ConfigEngine.sol';

struct TestVars {
  uint8 underlyingDecimals;
  string aTokenName;
  string aTokenSymbol;
  string variableDebtName;
  string variableDebtSymbol;
  address rateStrategy;
  address incentivesController;
  address treasury;
  bool useVirtualBalance;
}

struct TestReserveConfig {
  uint256 decimals;
  uint256 ltv;
  uint256 liquidationThreshold;
  uint256 liquidationBonus;
  uint256 reserveFactor;
  bool usageAsCollateralEnabled;
  bool borrowingEnabled;
  bool isActive;
  bool isFrozen;
  bool isPaused;
  bool isVirtualAccActive;
}

contract TestnetProcedures is Test, DeployUtils, FfiUtils, DefaultMarketInput {
  using MarketReportUtils for MarketReport;
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  address internal poolAdmin;

  address internal alice;
  address internal bob;
  address internal carol;

  uint256 internal alicePrivateKey;
  uint256 internal bobPrivateKey;
  uint256 internal carolPrivateKey;

  MarketReport internal report;
  ContractsReport internal contracts;
  TokenList internal tokenList;

  Roles internal roleList;

  TestnetERC20 internal usdx;
  TestnetERC20 internal wbtc;
  WETH9 internal weth;

  struct TokenList {
    address wbtc;
    address weth;
    address usdx;
    address gho;
  }

  struct EModeCategoryInput {
    uint8 id;
    uint16 ltv;
    uint16 lt;
    uint16 lb;
    string label;
  }

  function _initTestEnvironment(bool mintUserTokens, bool l2) internal {
    poolAdmin = makeAddr('POOL_ADMIN');

    alicePrivateKey = 0xA11CE;
    bobPrivateKey = 0xB0B;
    carolPrivateKey = 0xCA801;

    alice = vm.addr(alicePrivateKey);
    bob = vm.addr(bobPrivateKey);
    carol = vm.addr(carolPrivateKey);

    vm.label(alice, 'alice');
    vm.label(bob, 'bob');
    vm.label(carol, 'carol');

    (
      Roles memory roles,
      MarketConfig memory config,
      DeployFlags memory flags,
      MarketReport memory deployedContracts
    ) = _getMarketInput(poolAdmin);
    roleList = roles;
    flags.l2 = l2;

    // Etch the create2 factory
    vm.etch(
      0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7,
      hex'7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3'
    );

    (report, tokenList) = deployAaveV3TestnetAssets(
      poolAdmin,
      roles,
      config,
      flags,
      deployedContracts
    );

    contracts = report.toContractsReport();

    usdx = TestnetERC20(tokenList.usdx);
    wbtc = TestnetERC20(tokenList.wbtc);
    weth = WETH9(payable(tokenList.weth));

    vm.label(tokenList.usdx, 'USDX');
    vm.label(tokenList.wbtc, 'WBTC');
    vm.label(tokenList.weth, 'WETH');

    if (mintUserTokens) {
      // Perform setup of user positions
      uint256 mintAmount_USDX = 100_000e6;
      uint256 mintAmount_WBTC = 100e8;
      address[] memory users = new address[](3);
      users[0] = alice;
      users[1] = bob;
      users[2] = carol;

      for (uint256 x; x < users.length; x++) {
        vm.startPrank(poolAdmin);
        usdx.mint(users[x], mintAmount_USDX);
        wbtc.mint(users[x], mintAmount_WBTC);
        deal(address(weth), users[x], 100e18);
        vm.stopPrank();

        vm.startPrank(users[x]);
        usdx.approve(report.poolProxy, UINT256_MAX);
        wbtc.approve(report.poolProxy, UINT256_MAX);
        weth.approve(report.poolProxy, UINT256_MAX);
        vm.stopPrank();
      }
    }
  }

  function initTestEnvironment() public {
    _initTestEnvironment(true, false);
  }

  function initL2TestEnvironment() public {
    _initTestEnvironment(true, true);
  }

  function initTestEnvironment(bool mintUserTokens) public {
    _initTestEnvironment(mintUserTokens, false);
  }

  function detectFoundryLibrariesAndDelete() internal {
    bool found = _librariesPathExists();

    if (found) {
      _deleteLibrariesPath();
      console.log(
        'TestnetProcedures: FOUNDRY_LIBRARIES was detected and removed. Please run again "make test" to deploy libraries with a fresh compilation.'
      );
      revert('Retry the "make test" command.');
    }
  }

  function deployAaveV3Testnet(
    address deployer,
    Roles memory roles,
    MarketConfig memory config,
    DeployFlags memory flags,
    MarketReport memory deployedContracts
  ) internal returns (MarketReport memory testReport) {
    detectFoundryLibrariesAndDelete();

    vm.startPrank(deployer);
    MarketReport memory deployReport = AaveV3BatchOrchestration.deployAaveV3(
      deployer,
      roles,
      config,
      flags,
      deployedContracts
    );
    vm.stopPrank();

    return deployReport;
  }

  function deployAaveV3TestnetAssets(
    address deployer,
    Roles memory roles,
    MarketConfig memory config,
    DeployFlags memory flags,
    MarketReport memory deployedContracts
  ) internal returns (MarketReport memory, TokenList memory) {
    TokenList memory assetsList;

    assetsList.weth = address(new WETH9());

    config.wrappedNativeToken = assetsList.weth;

    MarketReport memory r = deployAaveV3Testnet(deployer, roles, config, flags, deployedContracts);

    AaveV3TestListing testnetListingPayload = new AaveV3TestListing(
      IAaveV3ConfigEngine(r.configEngine),
      roles.poolAdmin,
      assetsList.weth,
      r
    );

    assetsList.wbtc = testnetListingPayload.WBTC_ADDRESS();
    assetsList.usdx = testnetListingPayload.USDX_ADDRESS();
    assetsList.gho = testnetListingPayload.GHO_ADDRESS();

    ACLManager manager = ACLManager(r.aclManager);

    vm.prank(roles.poolAdmin);
    manager.addPoolAdmin(address(testnetListingPayload));

    testnetListingPayload.execute();

    return (r, assetsList);
  }

  function _getReserveConfig(
    address reserve,
    address dataProvider
  ) internal view returns (TestReserveConfig memory c) {
    (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      ,
      bool isActive,
      bool isFrozen
    ) = IPoolDataProvider(dataProvider).getReserveConfigurationData(reserve);
    c.decimals = decimals;
    c.ltv = ltv;
    c.liquidationThreshold = liquidationThreshold;
    c.liquidationBonus = liquidationBonus;
    c.reserveFactor = reserveFactor;
    c.usageAsCollateralEnabled = usageAsCollateralEnabled;
    c.borrowingEnabled = borrowingEnabled;
    c.isActive = isActive;
    c.isFrozen = isFrozen;
    c.isPaused = IPoolDataProvider(dataProvider).getPaused(reserve);
    c.isVirtualAccActive = IPoolDataProvider(dataProvider).getIsVirtualAccActive(reserve);

    return c;
  }

  function _concatStr(string memory a, uint256 b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, vm.toString(b)));
  }

  function _generateInitConfig(
    TestVars memory t,
    MarketReport memory r,
    address poolAdminUser,
    bool isValidDecimals
  ) internal returns (ConfiguratorInputTypes.InitReserveInput[] memory) {
    TestVars[] memory tArray = new TestVars[](1);
    tArray[0] = t;
    return _generateInitConfig(tArray, r, poolAdminUser, isValidDecimals);
  }

  function _generateInitConfig(
    TestVars[] memory t,
    MarketReport memory r,
    address poolAdminUser,
    bool isValidDecimals
  ) internal returns (ConfiguratorInputTypes.InitReserveInput[] memory) {
    ConfiguratorInputTypes.InitReserveInput[]
      memory configurations = new ConfiguratorInputTypes.InitReserveInput[](t.length);
    for (uint256 i = 0; i < t.length; i++) {
      configurations[i] = _generateInitReserveInput(t[i], r, poolAdminUser, isValidDecimals);
    }
    return configurations;
  }

  function _generateInitReserveInput(
    TestVars memory t,
    MarketReport memory r,
    address poolAdminUser,
    bool isValidDecimals
  ) internal returns (ConfiguratorInputTypes.InitReserveInput memory) {
    if (isValidDecimals) {
      t.underlyingDecimals = uint8(bound(t.underlyingDecimals, 6, 25));
    } else {
      t.underlyingDecimals = uint8(bound(t.underlyingDecimals, 0, 5));
    }

    ConfiguratorInputTypes.InitReserveInput memory input;
    input.aTokenImpl = r.aToken;
    input.underlyingAsset = address(
      new TestnetERC20('Misc Token', 'MISC', t.underlyingDecimals, poolAdminUser)
    );
    input.variableDebtTokenImpl = r.variableDebtToken;
    input.useVirtualBalance = t.useVirtualBalance;
    input.interestRateStrategyAddress = r.defaultInterestRateStrategy;
    input.treasury = t.treasury;
    input.incentivesController = r.rewardsControllerProxy;
    input.aTokenName = t.aTokenName;
    input.aTokenSymbol = t.aTokenSymbol;
    input.variableDebtTokenName = t.variableDebtName;
    input.variableDebtTokenSymbol = t.variableDebtSymbol;
    input.params = bytes('');
    input.interestRateData = abi.encode(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: 80_00,
        baseVariableBorrowRate: 1_00,
        variableRateSlope1: 4_00,
        variableRateSlope2: 60_00
      })
    );

    return input;
  }

  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * WadRayMath.RAY) / 10_000;
  }

  function _genCategoryOne() internal pure returns (EModeCategoryInput memory) {
    return EModeCategoryInput(1, 95_00, 96_00, 101_00, 'GROUP_A');
  }

  function _genCategoryTwo() internal pure returns (EModeCategoryInput memory) {
    return EModeCategoryInput(2, 96_00, 97_00, 101_50, 'GROUP_B');
  }

  function _calcPrice(uint256 price, uint256 percent) public pure returns (uint256) {
    if (percent == 0) return price;
    uint256 result = price.percentMul(percent);
    return result > price ? result - price : price - result;
  }

  function _calculateInterestRates(
    uint256 borrowAmount,
    address token
  ) internal view returns (uint256) {
    DataTypes.ReserveDataLegacy memory reserveData = IPool(report.poolProxy).getReserveData(token);
    TestReserveConfig memory reserveConfig = _getReserveConfig(token, report.protocolDataProvider);
    DefaultReserveInterestRateStrategyV2 rateStrategy = DefaultReserveInterestRateStrategyV2(
      reserveData.interestRateStrategyAddress
    );

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: borrowAmount,
      totalDebt: borrowAmount,
      reserveFactor: reserveConfig.reserveFactor,
      reserve: token,
      usingVirtualBalance: IPool(report.poolProxy).getConfiguration(token).getIsVirtualAccActive(),
      virtualUnderlyingBalance: IPool(report.poolProxy).getVirtualUnderlyingBalance(token)
    });

    (, uint256 expectedVariableBorrowRate) = rateStrategy.calculateInterestRates(input);
    return expectedVariableBorrowRate;
  }

  function _deployInterestRateStrategy() internal returns (address) {
    DefaultReserveInterestRateStrategyV2 strategy = new DefaultReserveInterestRateStrategyV2(
      report.poolAddressesProvider
    );

    return address(strategy);
  }

  function _getDefaultInterestRatesStrategyData() internal pure returns (bytes memory) {
    return
      abi.encode(
        IDefaultInterestRateStrategyV2.InterestRateData({
          optimalUsageRatio: 80_00,
          baseVariableBorrowRate: 10_00,
          variableRateSlope1: 4_00,
          variableRateSlope2: 60_00
        })
      );
  }
}
