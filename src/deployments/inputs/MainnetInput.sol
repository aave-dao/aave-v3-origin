// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './MarketInput.sol';

contract MainnetInput is MarketInput {
  address public constant EXECUTOR = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;
  address public constant GUARDIAN = 0x2CFe3ec4d5a6811f4B8067F0DE7e47DfA938Aa30;
  // todo: update this to the correct address
  address public constant RWA_ATOKEN_MANAGER_ADMIN = EXECUTOR;

  function _getMarketInput(
    address
  )
    internal
    pure
    override
    returns (
      Roles memory roles,
      MarketConfig memory config,
      DeployFlags memory flags,
      MarketReport memory deployedContracts
    )
  {
    roles.marketOwner = EXECUTOR;
    roles.emergencyAdmin = GUARDIAN;
    roles.poolAdmin = EXECUTOR;
    roles.rwaATokenManagerAdmin = RWA_ATOKEN_MANAGER_ADMIN;

    config.marketId = 'Aave V3 Horizon Market';
    config.providerId = 51;
    config.oracleDecimals = 8;
    config.flashLoanPremiumTotal = 0.0005e4;
    config.flashLoanPremiumToProtocol = 0.0004e4;
    config.wrappedNativeToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    config
      .marketReferenceCurrencyPriceInUsdProxyAggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // eth-usd chainlink price feed
    config.networkBaseTokenPriceInUsdProxyAggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // eth-usd chainlink price feed

    return (roles, config, flags, deployedContracts);
  }
}
