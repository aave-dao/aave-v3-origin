// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../interfaces/ILibraryReportStorage.sol';

abstract contract LibraryReportStorage is ILibraryReportStorage {
  LibrariesReport internal _librariesReport;

  function getLibrariesReport() public view returns (LibrariesReport memory) {
    return _librariesReport;
  }
}
