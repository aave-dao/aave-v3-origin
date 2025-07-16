// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './MarketInput.sol';

contract HorizonInput is MarketInput {
  address public constant AAVE_DAO_EXECUTOR = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;
  address public constant AAVE_DAO_COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
  bytes32 public constant POOL_ADMIN_ROLE = keccak256('POOL_ADMIN');
  address public constant PHASE_ONE_LISTING_EXECUTOR = 0xf046907a4371F7F027113bf751F3347459a08b71;

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
    bytes[] memory additionalRoles = new bytes[](1);
    additionalRoles[0] = abi.encode(POOL_ADMIN_ROLE, PHASE_ONE_LISTING_EXECUTOR);
    roles = Roles({
      marketOwner: AAVE_DAO_EXECUTOR,
      emergencyAdmin: AAVE_DAO_EXECUTOR,
      poolAdmin: AAVE_DAO_EXECUTOR,
      rwaATokenManagerAdmin: AAVE_DAO_EXECUTOR,
      additionalRoles: additionalRoles
    });

    config = MarketConfig({
      networkBaseTokenPriceInUsdProxyAggregator: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, // eth-usd chainlink price feed
      marketReferenceCurrencyPriceInUsdProxyAggregator: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, // eth-usd chainlink price feed
      marketId: 'Horizon RWA Market',
      oracleDecimals: 8,
      paraswapAugustusRegistry: address(0),
      l2SequencerUptimeFeed: address(0),
      l2PriceOracleSentinelGracePeriod: 0,
      providerId: 1,
      salt: bytes32(0),
      wrappedNativeToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
      flashLoanPremiumTotal: 0.0005e4,
      flashLoanPremiumToProtocol: 1e4,
      incentivesProxy: address(0),
      treasury: address(0),
      treasuryPartner: AAVE_DAO_COLLECTOR, // TreasuryCollector
      treasurySplitPercent: 50_00
    });

    return (roles, config, flags, deployedContracts);
  }
}
