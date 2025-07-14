// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {Default} from '../../scripts/DeployAaveV3MarketBatched.sol';
import {MarketReport, ContractsReport} from '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {MarketReportUtils} from '../../src/deployments/contracts/utilities/MarketReportUtils.sol';
import {IMetadataReporter} from '../../src/deployments/interfaces/IMetadataReporter.sol';

contract HorizonDeploymentTest is Test, Default {
    MarketReport internal marketReport;
    ContractsReport internal contracts;

    function setUp() public {
        string memory reportFilePath = run();
        IMetadataReporter metadataReporter = IMetadataReporter(
            _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
        );
        marketReport = metadataReporter.parseMarketReport(reportFilePath);
        contracts = MarketReportUtils.toContractsReport(marketReport);
    }

    function test_metadata() public {
        assertEq(contracts.poolAddressesProvider.getMarketId(), 'Horizon RWA Market');
    }
}