// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './MarketInput.sol';

contract MonadMarketInput is MarketInput {
  address internal constant OWNER = address(0xa9d0EAFF48cE1DF468f9eAeb7e628c413343F6A2); // Monad Governance Executor Lvl1
  address internal constant POOL_ADMIN = address(0xa9d0EAFF48cE1DF468f9eAeb7e628c413343F6A2);
  address internal constant EMERGENCY_ADMIN = address(0xc887455536CBD4e615B745e70CaCde15B3117e74); // the Aave Protocol Guardian on Monad.

  // Known Monad mainnet (chainId 143) addresses.
  address internal constant WMON = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;
  address internal constant MON_USD_FEED = 0xBcD78f76005B7515837af6b50c7C52BCf73822fb;

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
    roles.marketOwner = OWNER;
    roles.poolAdmin = POOL_ADMIN;
    roles.emergencyAdmin = EMERGENCY_ADMIN;

    config.marketId = 'Aave V3 Monad';
    config.salt = 'V3-MONAD';
    config.providerId = 1;
    config.oracleDecimals = 8;
    config.flashLoanPremium = 0.0005e4;
    config.wrappedNativeToken = WMON;
    // Both aggregators point to the native-token/USD feed, matching deployed markets (e.g. Base, where
    // both resolve to ETH/USD).
    config.networkBaseTokenPriceInUsdProxyAggregator = MON_USD_FEED;
    config.marketReferenceCurrencyPriceInUsdProxyAggregator = MON_USD_FEED;
    // config.treasury / config.incentivesProxy left unset : fresh Collector + EmissionManager.

    return (roles, config, flags, deployedContracts);
  }
}
