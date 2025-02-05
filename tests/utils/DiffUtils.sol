// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Test.sol';

/**
 * Helper contract to invoke json diffing via js
 */
contract DiffUtils is Test {
  using stdJson for string;

  /**
   * @dev generates the diff between two reports
   */
  function diffReports(string memory reportBefore, string memory reportAfter) internal {
    string memory outPath = string(
      abi.encodePacked('./diffs/', reportBefore, '_', reportAfter, '.md')
    );
    string memory beforePath = string(abi.encodePacked('./reports/', reportBefore, '.json'));
    string memory afterPath = string(abi.encodePacked('./reports/', reportAfter, '.json'));

    string[] memory inputs = new string[](7);
    inputs[0] = 'npx';
    inputs[1] = '@bgd-labs/aave-cli@^1.1.17';
    inputs[2] = 'diff-snapshots';
    inputs[3] = beforePath;
    inputs[4] = afterPath;
    inputs[5] = '-o';
    inputs[6] = outPath;
    vm.ffi(inputs);
  }
}
