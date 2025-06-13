// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {AaveV3LibrariesBatch1} from '../../src/deployments/projects/aave-v3-libraries/AaveV3LibrariesBatch1.sol';
import {FfiUtils} from '../../src/deployments/contracts/utilities/FfiUtils.sol';
import {IMetadataReporter} from '../../src/deployments/interfaces/IMetadataReporter.sol';
import {DeployUtils} from '../../src/deployments/contracts/utilities/DeployUtils.sol';

/**
 * @dev Deploy libraries in batch using CREATE2, this optional
 *      script allows to deploy the first 4 libraries of Aave V3 protocol
 *      and it saves the output to FOUNDRY_LIBRARIES env variable.
 *      The script will ask you to re-execute if FOUNDRY_LIBRARIES
 *      is set, due that setting mutates the bytecode and could result
 *      in different library addresses.
 */
contract LibraryPreCompileOne is FfiUtils, Script, DeployUtils {
  function run() external {
    bool found = _librariesPathExists();

    if (found) {
      address lastLib = _getLatestLibraryAddress();
      if (lastLib.code.length > 0) {
        console.log('[LibraryPreCompileOne] Library detected. Skipping re-deployment.');
        return;
      } else {
        _deleteLibrariesPath();
        console.log(
          'LibraryPreCompileOne: FOUNDRY_LIBRARIES was detected and removed. Please run again to deploy libraries with a fresh compilation.'
        );
        revert('RETRY AGAIN');
      }
    }

    _deployAndWriteLibrariesConfig();
  }

  function _deployAndWriteLibrariesConfig() internal {
    vm.startBroadcast();
    AaveV3LibrariesBatch1 batch1 = new AaveV3LibrariesBatch1();
    vm.stopBroadcast();
    LibrariesReport memory report = batch1.getLibrariesReport();

    string memory librariesSolcString = string(abi.encodePacked(getLibraryString1(report)));

    // Write deployment JSON report at /reports
    IMetadataReporter metadataReporter = IMetadataReporter(
      _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
    );
    metadataReporter.writeJsonReportLibraryBatch1(report);

    string memory sedCommand = string(
      abi.encodePacked('echo FOUNDRY_LIBRARIES=', librariesSolcString, ' >> .env')
    );
    string[] memory command = new string[](3);

    command[0] = 'bash';
    command[1] = '-c';
    command[2] = string(abi.encodePacked('response="$(', sedCommand, ')"; $response;'));
    vm.ffi(command);

    console.log(
      'LibraryPreCompileOne: FOUNDRY_LIBRARIES set first batch of libraries, run LibraryPreCompileTwo script to settle all AaveV3 libraries.'
    );
  }

  function getLibraryString1(LibrariesReport memory report) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          'src/contracts/protocol/libraries/logic/BorrowLogic.sol:BorrowLogic:',
          vm.toString(report.borrowLogic),
          ',',
          'src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol:ConfiguratorLogic:',
          vm.toString(report.configuratorLogic),
          ',',
          'src/contracts/protocol/libraries/logic/EModeLogic.sol:EModeLogic:',
          vm.toString(report.eModeLogic)
        )
      );
  }
}
