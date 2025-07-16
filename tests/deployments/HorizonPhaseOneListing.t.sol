// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Test, Vm} from 'forge-std/Test.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {MarketReport, ContractsReport} from '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {Default} from '../../scripts/DeployAaveV3MarketBatched.sol';
import {MarketReportUtils} from '../../src/deployments/contracts/utilities/MarketReportUtils.sol';
import {ConfigureHorizonPhaseOne} from '../../scripts/misc/ConfigureHorizonPhaseOne.sol';
import {ReserveConfiguration} from '../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IMetadataReporter} from '../../src/deployments/interfaces/IMetadataReporter.sol';
import {IRevenueSplitter} from '../../src/contracts/treasury/IRevenueSplitter.sol';
import {IDefaultInterestRateStrategyV2} from '../../src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {IERC20Detailed} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IACLManager} from '../../src/contracts/interfaces/IACLManager.sol';
import {IAToken} from '../../src/contracts/interfaces/IAToken.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ProxyHelpers} from '../utils/ProxyHelpers.sol';

contract ConfigureHorizonPhaseOneTest is Test, ConfigureHorizonPhaseOne {
  function run(address deployer, string memory reportFilePath) public {
    _run(deployer, reportFilePath);
  }
}

abstract contract HorizonListingBaseTest is Test {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  IPool internal pool;
  IRevenueSplitter internal revenueSplitter;
  IDefaultInterestRateStrategyV2 internal defaultInterestRateStrategy;
  address internal aTokenImpl;
  address internal rwaATokenImpl;
  address internal variableDebtTokenImpl;

  struct TokenListingParams {
    bool isGho;
    bool isRwa;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    uint256 supplyCap;
    uint256 borrowCap;
    uint256 reserveFactor;
    bool enabledToBorrow;
    bool borrowableInIsolation;
    bool withSiloedBorrowing;
    bool flashloanable;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 debtCeiling;
    uint256 liqProtocolFee;
    IDefaultInterestRateStrategyV2.InterestRateDataRay interestRateData;
  }

  function initEnvironment(
    address pool_,
    address revenueSplitter_,
    address defaultInterestRateStrategy_,
    address aTokenImpl_,
    address rwaATokenImpl_,
    address variableDebtTokenImpl_
  ) internal virtual {
    pool = IPool(pool_);
    revenueSplitter = IRevenueSplitter(revenueSplitter_);
    defaultInterestRateStrategy = IDefaultInterestRateStrategyV2(defaultInterestRateStrategy_);
    aTokenImpl = aTokenImpl_;
    rwaATokenImpl = rwaATokenImpl_;
    variableDebtTokenImpl = variableDebtTokenImpl_;
  }

  function getListingExecutor() internal view virtual returns (address);

  function test_listingExecutor() public {
    assertEq(
      IACLManager(pool.ADDRESSES_PROVIDER().getACLManager()).isPoolAdmin(getListingExecutor()),
      false
    );
  }

  function test_getConfiguration(address token, TokenListingParams memory params) private {
    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(token);
    assertEq(config.getSupplyCap(), params.supplyCap);
    assertEq(config.getBorrowCap(), params.borrowCap);
    assertEq(config.getIsVirtualAccActive(), !params.isGho);
    assertEq(config.getBorrowingEnabled(), params.enabledToBorrow);
    assertEq(config.getBorrowableInIsolation(), params.borrowableInIsolation);
    assertEq(config.getSiloedBorrowing(), params.withSiloedBorrowing);
    assertEq(config.getFlashLoanEnabled(), params.flashloanable);
    assertEq(config.getReserveFactor(), params.reserveFactor);
    assertEq(config.getLtv(), params.ltv);
    assertEq(config.getLiquidationThreshold(), params.liquidationThreshold);
    assertEq(config.getLiquidationBonus(), params.liquidationBonus);
    assertEq(config.getDebtCeiling(), params.debtCeiling);
    assertEq(config.getLiquidationProtocolFee(), params.liqProtocolFee);
    assertEq(config.getPaused(), true);
  }

  function test_interestRateStrategy(address token, TokenListingParams memory params) private {
    assertEq(
      pool.getReserveData(token).interestRateStrategyAddress,
      address(defaultInterestRateStrategy)
    );
    assertEq(defaultInterestRateStrategy.getInterestRateData(token), params.interestRateData);
  }

  function test_aToken(address token, TokenListingParams memory params) private {
    address aToken = pool.getReserveAToken(token);
    assertEq(IERC20Detailed(aToken).name(), params.aTokenName);
    assertEq(IERC20Detailed(aToken).symbol(), params.aTokenSymbol);
    assertEq(IAToken(aToken).RESERVE_TREASURY_ADDRESS(), address(revenueSplitter));

    address currentATokenImpl = ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
      vm,
      aToken
    );
    if (params.isRwa) {
      assertEq(currentATokenImpl, rwaATokenImpl);
      vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
      IAToken(aToken).approve(address(0), 0);
    } else {
      assertEq(currentATokenImpl, aTokenImpl);
      IAToken(aToken).approve(makeAddr('randomAddress'), 1);
    }
  }

  function test_variableDebtToken(address token, TokenListingParams memory params) private {
    address variableDebtToken = pool.getReserveVariableDebtToken(token);
    assertEq(IERC20Detailed(variableDebtToken).name(), params.variableDebtTokenName);
    assertEq(IERC20Detailed(variableDebtToken).symbol(), params.variableDebtTokenSymbol);
    assertEq(
      ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(vm, variableDebtToken),
      variableDebtTokenImpl
    );
  }

  function test_listing(address token, TokenListingParams memory params) internal {
    test_getConfiguration(token, params);
    test_interestRateStrategy(token, params);
    test_aToken(token, params);
    test_variableDebtToken(token, params);
  }

  function assertEq(
    IDefaultInterestRateStrategyV2.InterestRateDataRay memory a,
    IDefaultInterestRateStrategyV2.InterestRateDataRay memory b
  ) internal {
    assertEq(
      a.optimalUsageRatio,
      b.optimalUsageRatio,
      'assertEq(interestRateData): optimalUsageRatio'
    );
    assertEq(
      a.baseVariableBorrowRate,
      b.baseVariableBorrowRate,
      'assertEq(interestRateData): baseVariableBorrowRate'
    );
    assertEq(
      a.variableRateSlope1,
      b.variableRateSlope1,
      'assertEq(interestRateData): variableRateSlope1'
    );
    assertEq(
      a.variableRateSlope2,
      b.variableRateSlope2,
      'assertEq(interestRateData): variableRateSlope2'
    );
    assertEq(abi.encode(a), abi.encode(b), 'assertEq(interestRateData): all fields');
  }
}

contract HorizonListingMainnetTest is HorizonListingBaseTest {
  address internal constant DEPLOYER = 0xA22f39d5fEb10489F7FA84C2C545BAc4EA48eBB7;
  address internal constant LISTING_EXECUTOR = 0xf046907a4371F7F027113bf751F3347459a08b71;

  address internal constant GHO_ADDRESS = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
  address internal constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address internal constant RLUSD_ADDRESS = 0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD;
  address internal constant USTB_ADDRESS = 0x43415eB6ff9DB7E26A15b704e7A3eDCe97d31C4e;
  address internal constant USCC_ADDRESS = 0x14d60E7FDC0D71d8611742720E4C50E7a974020c;
  address internal constant USYC_ADDRESS = 0x136471a34f6ef19fE571EFFC1CA711fdb8E49f2b;

  TokenListingParams internal GHO_TOKEN_LISTING_PARAMS =
    TokenListingParams({
      aTokenName: 'Aave Horizon RWA GHO',
      aTokenSymbol: 'aHRwaGHO',
      variableDebtTokenName: 'Aave Horizon RWA Variable Debt GHO',
      variableDebtTokenSymbol: 'variableDebtHRwaGHO',
      isGho: true,
      isRwa: false,
      supplyCap: 5_000_000,
      borrowCap: 4_000_000,
      reserveFactor: 15_00,
      enabledToBorrow: true,
      borrowableInIsolation: false,
      withSiloedBorrowing: false,
      flashloanable: true,
      ltv: 0,
      liquidationThreshold: 0,
      liquidationBonus: 0,
      debtCeiling: 0,
      liqProtocolFee: 0,
      interestRateData: IDefaultInterestRateStrategyV2.InterestRateDataRay({
        optimalUsageRatio: 0.92e27,
        baseVariableBorrowRate: 0.035e27,
        variableRateSlope1: 0.0125e27,
        variableRateSlope2: 0.35e27
      })
    });

  function setUp() public virtual {
    vm.createSelectFork('mainnet');
  }

  function getListingExecutor() internal pure override returns (address) {
    return LISTING_EXECUTOR;
  }
}

contract HorizonPhaseOneListingTest is HorizonListingMainnetTest, Default {
  MarketReport internal marketReport;
  ContractsReport internal contracts;

  function setUp() public override {
    super.setUp();

    string memory reportFilePath = run();

    IMetadataReporter metadataReporter = IMetadataReporter(
      _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
    );
    marketReport = metadataReporter.parseMarketReport(reportFilePath);
    contracts = MarketReportUtils.toContractsReport(marketReport);

    ConfigureHorizonPhaseOneTest configureHorizonPhaseOneTest = new ConfigureHorizonPhaseOneTest();
    configureHorizonPhaseOneTest.run(DEPLOYER, reportFilePath);

    initEnvironment(
      marketReport.poolProxy,
      marketReport.revenueSplitter,
      marketReport.defaultInterestRateStrategy,
      marketReport.aToken,
      marketReport.rwaAToken,
      marketReport.variableDebtToken
    );
  }

  function test_listing_GHO() public {
    test_listing(GHO_ADDRESS, GHO_TOKEN_LISTING_PARAMS);
  }

  // function test_listing_USDC() public {
  //   _checkTokenListing(
  //     USDC_ADDRESS,
  //     TokenListingParams({supplyCap: 5_000_000, borrowCap: 4_000_000})
  //   );
  // }

  // function test_listing_RLUSD() public {
  //   _checkTokenListing(
  //     RLUSD_ADDRESS,
  //     TokenListingParams({supplyCap: 5_000_000, borrowCap: 4_000_000})
  //   );
  // }

  // function test_listing_USTB() public {
  //   _checkTokenListing(USTB_ADDRESS, TokenListingParams({supplyCap: 3_000_000, borrowCap: 0}));
  // }

  // function test_listing_USCC() public {
  //   _checkTokenListing(USCC_ADDRESS, TokenListingParams({supplyCap: 3_000_000, borrowCap: 0}));
  // }

  // function test_listing_USYC() public {
  //   _checkTokenListing(USYC_ADDRESS, TokenListingParams({supplyCap: 3_000_000, borrowCap: 0}));
  // }
}
