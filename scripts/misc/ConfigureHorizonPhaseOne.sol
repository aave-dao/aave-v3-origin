// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {MarketReport} from '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {HorizonPhaseOneListing} from '../../src/deployments/inputs/HorizonPhaseOneListing.sol';
import {IMetadataReporter} from '../../src/deployments/interfaces/IMetadataReporter.sol';
import {DeployUtils} from '../../src/deployments/contracts/utilities/DeployUtils.sol';
import {Script} from 'forge-std/Script.sol';

contract ConfigureHorizonPhaseOne is Script, DeployUtils {
    function run(string memory reportPath) public {
        _run(msg.sender, reportPath);
    }

    function _run(address deployer, string memory reportPath) internal {
        // Configure Horizon Phase One Listing
        IMetadataReporter metadataReporter = IMetadataReporter(
            _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
        );
        MarketReport memory report = metadataReporter.parseMarketReport(reportPath);

        vm.startBroadcast(deployer);
        HorizonPhaseOneListing horizonInitialListing = new HorizonPhaseOneListing(report);
        horizonInitialListing.ACL_MANAGER().addPoolAdmin(address(horizonInitialListing));
        horizonInitialListing.execute();
        vm.stopBroadcast();
    }
}