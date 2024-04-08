// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMarketReportTypes.sol';

interface IMetadataReporter {
  function writeJsonReportMarket(MarketReport memory report) external;

  function writeJsonReportLibraryBatch1(LibrariesReport memory libraries) external;

  function writeJsonReportLibraryBatch2(LibrariesReport memory libraries) external;

  function getTimestamp() external returns (string memory result);

  function getGitModuleVersion() external returns (string memory commit, string memory branch);
}
