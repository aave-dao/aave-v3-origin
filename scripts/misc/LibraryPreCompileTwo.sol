// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {AaveV3LibrariesBatch2} from '../../src/deployments/projects/aave-v3-libraries/AaveV3LibrariesBatch2.sol';
import {FfiUtils} from '../../src/deployments/contracts/utilities/FfiUtils.sol';
import {IMetadataReporter} from '../../src/deployments/interfaces/IMetadataReporter.sol';
import {DeployUtils} from '../../src/deployments/contracts/utilities/DeployUtils.sol';

/**
 * @dev Deploy libraries in batch using CREATE2, this optional
 *      script allows to deploy the next 4 libraries of Aave V3 protocol
 *      and it appends the output to FOUNDRY_LIBRARIES env variable.
 *      The script will ask you to execute "LibraryPreCompileOne"
 *      if FOUNDRY_LIBRARIES is not set, due BorrowLogic is a needed
 *      dependency of FlashLoanLogic library.
 */
contract LibraryPreCompileTwo is FfiUtils, Script, DeployUtils {
  function run() external {
    bool found = _librariesPathExists();

    if (found) {
      address lastLib = _getSupplyLibraryAddress();
      if (lastLib.code.length > 0) {
        console.log('[LibraryPreCompileTwo] SupplyLibrary detected. Skipping re-deployment.');
        return;
      }
    }
    _deployAndWriteLibrariesConfig();
  }

  function _deployAndWriteLibrariesConfig() internal {
    verifyEnvironment();

    vm.startBroadcast();
    AaveV3LibrariesBatch2 batch2 = new AaveV3LibrariesBatch2();
    vm.stopBroadcast();
    LibrariesReport memory report = batch2.getLibrariesReport();

    // Write deployment JSON report at /reports
    IMetadataReporter metadataReporter = IMetadataReporter(
      _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
    );
    metadataReporter.writeJsonReportLibraryBatch2(report);

    string memory librariesSolcString = string(abi.encodePacked(getLibraryString2(report)));

    string memory sedCommand = string(
      abi.encodePacked(
        "sed -i.bak -r 's (FOUNDRY_LIBRARIES=.*) \\1",
        librariesSolcString,
        " ' .env && rm .env.bak"
      )
    );
    string[] memory command = new string[](3);

    command[0] = 'bash';
    command[1] = '-c';
    command[2] = string(abi.encodePacked('response="$(', sedCommand, ')"; $response;'));
    vm.ffi(command);

    console.log(
      'LibraryPreCompileTwo: FOUNDRY_LIBRARIES updated with all AaveV3 libraries via CREATE2.'
    );
  }

  function getLibraryString2(LibrariesReport memory report) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          ',',
          'src/contracts/protocol/libraries/logic/FlashLoanLogic.sol:FlashLoanLogic:',
          vm.toString(report.flashLoanLogic),
          ',',
          'src/contracts/protocol/libraries/logic/LiquidationLogic.sol:LiquidationLogic:',
          vm.toString(report.liquidationLogic),
          ',',
          'src/contracts/protocol/libraries/logic/PoolLogic.sol:PoolLogic:',
          vm.toString(report.poolLogic),
          ',',
          'src/contracts/protocol/libraries/logic/SupplyLogic.sol:SupplyLogic:',
          vm.toString(report.supplyLogic)
        )
      );
  }

  function verifyEnvironment() internal {
    string
      memory checkCommand = '[ -e .env ] && grep -q "FOUNDRY_LIBRARIES" .env && echo true || echo false';
    string[] memory command = new string[](3);

    command[0] = 'bash';
    command[1] = '-c';
    command[2] = string(
      abi.encodePacked(
        'response="$(',
        checkCommand,
        ')"; cast abi-encode "response(bool)" $response;'
      )
    );
    bytes memory res = vm.ffi(command);

    bool found = abi.decode(res, (bool));

    if (found == false) {
      revert(
        'LibraryPreCompileTwo: FOUNDRY_LIBRARIES not found, please run LibraryPrecompileOne first.'
      );
    }
  }
}
