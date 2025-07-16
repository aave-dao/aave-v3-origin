// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Ownable} from '../../src/contracts/dependencies/openzeppelin/contracts/Ownable.sol';
import {Default} from '../../scripts/DeployAaveV3MarketBatched.sol';
import {MarketReport, ContractsReport, MarketConfig} from '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {MarketReportUtils} from '../../src/deployments/contracts/utilities/MarketReportUtils.sol';
import {IMetadataReporter} from '../../src/deployments/interfaces/IMetadataReporter.sol';
import {Test} from 'forge-std/Test.sol';

contract HorizonDeploymentTest is Test, Default {
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
  }

  function test_HorizonInput() public {
    (, MarketConfig memory config, , ) = _getMarketInput(address(0));
    assertEq(contracts.poolAddressesProvider.getMarketId(), config.marketId);
    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderAddressById(config.providerId),
      marketReport.poolAddressesProvider
    );
    assertEq(contracts.aaveOracle.BASE_CURRENCY_UNIT(), 10 ** config.oracleDecimals);
    assertEq(address(contracts.wrappedTokenGateway.WETH()), config.wrappedNativeToken);
    assertEq(contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL(), config.flashLoanPremiumTotal);
    assertEq(
      contracts.poolProxy.FLASHLOAN_PREMIUM_TO_PROTOCOL(),
      config.flashLoanPremiumToProtocol
    );
    assertEq(contracts.treasury.isFundsAdmin(AAVE_DAO_EXECUTOR), true);
    assertEq(contracts.revenueSplitter.RECIPIENT_A(), marketReport.treasury);
    assertEq(contracts.revenueSplitter.RECIPIENT_B(), config.treasuryPartner);
    assertEq(contracts.revenueSplitter.SPLIT_PERCENTAGE_RECIPIENT_A(), config.treasurySplitPercent);
  }

  function test_RewardsController() public {
    assertEq(contracts.rewardsControllerProxy.EMISSION_MANAGER(), marketReport.emissionManager);
    assertEq(Ownable(address(contracts.emissionManager)).owner(), AAVE_DAO_EXECUTOR);
  }
}
