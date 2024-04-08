// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMarketReportTypes.sol';

interface ILibraryReportStorage {
  function getLibrariesReport() external view returns (LibrariesReport memory);
}
