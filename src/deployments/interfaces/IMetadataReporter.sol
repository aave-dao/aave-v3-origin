// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMarketReportTypes.sol';

interface IMetadataReporter {
  function writeJsonReportMarket(
    MarketReport memory report
  ) external returns (string memory filePath);

  function parseMarketReport(
    string memory reportFilePath
  ) external view returns (MarketReport memory report);

  function writeJsonReportLibraryBatch1(LibrariesReport memory libraries) external;

  function writeJsonReportLibraryBatch2(LibrariesReport memory libraries) external;

  function getTimestamp() external returns (string memory result);

  function getGitModuleVersion() external returns (string memory commit, string memory branch);
}
