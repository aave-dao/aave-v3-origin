// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../interfaces/IMarketReportTypes.sol';

abstract contract MarketInput {
  function _getMarketInput(
    address
  )
    internal
    pure
    virtual
    returns (
      Roles memory roles,
      MarketConfig memory config,
      DeployFlags memory flags,
      MarketReport memory deployedContracts
    );
}
