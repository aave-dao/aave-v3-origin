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
import {IAToken} from '../../src/contracts/interfaces/IAToken.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';


contract ConfigureHorizonPhaseOneTest is Test, ConfigureHorizonPhaseOne {
  function run(address deployer, string memory reportFilePath) public {
    _run(deployer, reportFilePath);
  }
}

contract HorizonListingBaseTest is Test {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  IPool internal pool;
  IRevenueSplitter internal revenueSplitter;

  struct TokenListingParams {
    uint256 supplyCap;
    uint256 borrowCap;
  }

  function setUp(address _pool, address _revenueSplitter) internal {
    pool = IPool(_pool);
    revenueSplitter = IRevenueSplitter(_revenueSplitter);
  }


  function _checkTokenListing(address token, TokenListingParams memory params) internal {
    assertEq(pool.getConfiguration(token).getSupplyCap(), params.supplyCap);
    assertEq(pool.getConfiguration(token).getBorrowCap(), params.borrowCap);
    assertEq(IAToken(pool.getReserveAToken(token)).RESERVE_TREASURY_ADDRESS(), address(revenueSplitter));
  }
}

contract HorizonPhaseOneListingTest is HorizonListingBaseTest, Default {
  address internal constant GHO_ADDRESS = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
  address internal constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address internal constant RLUSD_ADDRESS = 0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD;
  address internal constant USTB_ADDRESS = 0x43415eB6ff9DB7E26A15b704e7A3eDCe97d31C4e;
  address internal constant USCC_ADDRESS = 0x14d60E7FDC0D71d8611742720E4C50E7a974020c;
  address internal constant USYC_ADDRESS = 0x136471a34f6ef19fE571EFFC1CA711fdb8E49f2b;

  MarketReport internal marketReport;
  ContractsReport internal contracts;

  function setUp() public {
    vm.createSelectFork('mainnet');

    string memory reportFilePath = run();

    IMetadataReporter metadataReporter = IMetadataReporter(
      _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
    );
    marketReport = metadataReporter.parseMarketReport(reportFilePath);
    contracts = MarketReportUtils.toContractsReport(marketReport);

    ConfigureHorizonPhaseOneTest configureHorizonPhaseOneTest = new ConfigureHorizonPhaseOneTest();
    configureHorizonPhaseOneTest.run(DEPLOYER, reportFilePath);

    super.setUp(marketReport.poolProxy, marketReport.revenueSplitter);
  }

  function test_listing_GHO() public {
    _checkTokenListing(GHO_ADDRESS, TokenListingParams({supplyCap: 5_000_000, borrowCap: 4_000_000}));
  }

  function test_listing_USDC() public {
    _checkTokenListing(USDC_ADDRESS, TokenListingParams({supplyCap: 5_000_000, borrowCap: 4_000_000}));
  }

  function test_listing_RLUSD() public {
    _checkTokenListing(RLUSD_ADDRESS, TokenListingParams({supplyCap: 5_000_000, borrowCap: 4_000_000}));
  }

  function test_listing_USTB() public {
    _checkTokenListing(USTB_ADDRESS, TokenListingParams({supplyCap: 3_000_000, borrowCap: 0}));
  }

  function test_listing_USCC() public {
    _checkTokenListing(USCC_ADDRESS, TokenListingParams({supplyCap: 3_000_000, borrowCap: 0}));
  }

  function test_listing_USYC() public {
    _checkTokenListing(USYC_ADDRESS, TokenListingParams({supplyCap: 3_000_000, borrowCap: 0}));
  }
}
