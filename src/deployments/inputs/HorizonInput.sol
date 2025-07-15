// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './MarketInput.sol';

contract HorizonInput is MarketInput {
  address public constant DEPLOYER = 0xA22f39d5fEb10489F7FA84C2C545BAc4EA48eBB7;
  bytes32 public constant POOL_ADMIN_ROLE = keccak256('POOL_ADMIN');
  address public constant PHASE_ONE_LISTING_EXECUTOR = address(0); // todo

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
      marketOwner: DEPLOYER,
      emergencyAdmin: DEPLOYER,
      poolAdmin: DEPLOYER,
      rwaATokenManagerAdmin: DEPLOYER,
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
      treasuryPartner: 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c, // TreasuryCollector
      treasurySplitPercent: 50_00
    });

    return (roles, config, flags, deployedContracts);
  }
}
