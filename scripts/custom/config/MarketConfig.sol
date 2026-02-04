// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title MarketConfig
 * @notice Configuration library for UBC Market deployments
 * @dev Contains reserve configs, rate strategies, and market parameters
 */
library MarketConfig {
  // ══════════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ══════════════════════════════════════════════════════════════════════════════

  uint256 constant RAY = 1e27;
  uint256 constant BPS = 10000;

  // ══════════════════════════════════════════════════════════════════════════════
  // RESERVE CONFIG STRUCT
  // ══════════════════════════════════════════════════════════════════════════════

  struct ReserveParams {
    string symbol;
    address tokenAddress;
    address oracleAddress;
    uint256 baseLTVAsCollateral; // bps
    uint256 liquidationThreshold; // bps
    uint256 liquidationBonus; // bps (10000 = 0%, 10500 = 5% bonus)
    uint256 liquidationProtocolFee; // bps
    uint256 reserveFactor; // bps
    uint256 supplyCap; // in token units
    uint256 borrowCap; // in token units
    uint256 debtCeiling; // in USD cents (100 = $1)
    uint8 decimals;
    bool borrowingEnabled;
    bool flashLoanEnabled;
    bool borrowableIsolation;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // RATE STRATEGY STRUCT
  // ══════════════════════════════════════════════════════════════════════════════

  struct RateStrategyParams {
    string name;
    uint256 optimalUsageRatio; // RAY
    uint256 baseVariableBorrowRate; // RAY
    uint256 variableRateSlope1; // RAY
    uint256 variableRateSlope2; // RAY
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // RATE STRATEGIES
  // ══════════════════════════════════════════════════════════════════════════════

  function getRateStrategyReserveOne() internal pure returns (RateStrategyParams memory) {
    return
      RateStrategyParams({
        name: 'rateStrategyReserveOne',
        optimalUsageRatio: (80 * RAY) / 100, // 80%
        baseVariableBorrowRate: 0,
        variableRateSlope1: (4 * RAY) / 100, // 4%
        variableRateSlope2: (5 * RAY) // 500%
      });
  }

  function getRateStrategyVolatile() internal pure returns (RateStrategyParams memory) {
    return
      RateStrategyParams({
        name: 'rateStrategyVolatile',
        optimalUsageRatio: (80 * RAY) / 100, // 80%
        baseVariableBorrowRate: 0,
        variableRateSlope1: (20 * RAY) / 100, // 20%
        variableRateSlope2: (10 * RAY) // 1000%
      });
  }

  function getRateStrategyJpyUBI() internal pure returns (RateStrategyParams memory) {
    return
      RateStrategyParams({
        name: 'rateStrategyJpyUBI',
        optimalUsageRatio: (90 * RAY) / 100, // 90%
        baseVariableBorrowRate: 0,
        variableRateSlope1: (2 * RAY) / 100, // 2%
        variableRateSlope2: (60 * RAY) / 100 // 60%
      });
  }
}

/**
 * @title UBCMarketConfig
 * @notice UBC Market reserve configurations
 */
library UBCMarketConfig {
  using MarketConfig for *;

  // ══════════════════════════════════════════════════════════════════════════════
  // STABLECOIN CONFIGS
  // ══════════════════════════════════════════════════════════════════════════════

  function getUSDCConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'USDC',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 8500, // 85%
        liquidationThreshold: 9000, // 90%
        liquidationBonus: 10700, // 7% bonus
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 5_000_000,
        borrowCap: 0,
        debtCeiling: 200_000_000, // $2M
        decimals: 6,
        borrowingEnabled: false,
        flashLoanEnabled: false,
        borrowableIsolation: false
      });
  }

  function getUSDTConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'USDT',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 8500, // 85%
        liquidationThreshold: 9000, // 90%
        liquidationBonus: 10700, // 7% bonus
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 5_000_000,
        borrowCap: 0,
        debtCeiling: 200_000_000, // $2M
        decimals: 6,
        borrowingEnabled: false,
        flashLoanEnabled: false,
        borrowableIsolation: false
      });
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BLUE CHIP CONFIGS
  // ══════════════════════════════════════════════════════════════════════════════

  function getCbBTCConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'cbBTC',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 8000, // 80%
        liquidationThreshold: 8500, // 85%
        liquidationBonus: 10700, // 7% bonus
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 5_000_000,
        borrowCap: 0,
        debtCeiling: 200_000_000, // $2M
        decimals: 8,
        borrowingEnabled: false,
        flashLoanEnabled: false,
        borrowableIsolation: false
      });
  }

  function getLINKConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'LINK',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 8000, // 80%
        liquidationThreshold: 8500, // 85%
        liquidationBonus: 10700, // 7% bonus
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 10_000_000,
        borrowCap: 0,
        debtCeiling: 200_000_000, // $2M
        decimals: 18,
        borrowingEnabled: false,
        flashLoanEnabled: false,
        borrowableIsolation: false
      });
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // VOLATILE ASSET CONFIGS (ISOLATED)
  // ══════════════════════════════════════════════════════════════════════════════

  function getVIRTUALSConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'VIRTUALS',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 3000, // 30%
        liquidationThreshold: 5000, // 50%
        liquidationBonus: 11000, // 10% bonus
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 5_000_000,
        borrowCap: 0,
        debtCeiling: 100_000_000, // $1M
        decimals: 18,
        borrowingEnabled: false,
        flashLoanEnabled: false,
        borrowableIsolation: false
      });
  }

  function getFETConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'FET',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 3000, // 30%
        liquidationThreshold: 5000, // 50%
        liquidationBonus: 11000, // 10% bonus
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 5_000_000,
        borrowCap: 0,
        debtCeiling: 100_000_000, // $1M
        decimals: 18,
        borrowingEnabled: false,
        flashLoanEnabled: false,
        borrowableIsolation: false
      });
  }

  function getRENDERConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'RENDER',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 3000, // 30%
        liquidationThreshold: 5000, // 50%
        liquidationBonus: 11000, // 10% bonus
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 5_000_000,
        borrowCap: 0,
        debtCeiling: 100_000_000, // $1M
        decimals: 18,
        borrowingEnabled: false,
        flashLoanEnabled: false,
        borrowableIsolation: false
      });
  }

  function getCUSDConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'CUSD',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 6000, // 60%
        liquidationThreshold: 7000, // 70%
        liquidationBonus: 10700, // 7% bonus
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 5_000_000,
        borrowCap: 0,
        debtCeiling: 100_000_000, // $1M
        decimals: 18,
        borrowingEnabled: false,
        flashLoanEnabled: false,
        borrowableIsolation: false
      });
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // JPYUBI CONFIG (ONLY BORROWABLE ASSET)
  // ══════════════════════════════════════════════════════════════════════════════

  function getJpyUBIConfig(address token, address oracle) internal pure returns (MarketConfig.ReserveParams memory) {
    return
      MarketConfig.ReserveParams({
        symbol: 'jpyUBI',
        tokenAddress: token,
        oracleAddress: oracle,
        baseLTVAsCollateral: 0, // Not collateral
        liquidationThreshold: 0, // Not collateral
        liquidationBonus: 0, // Not collateral
        liquidationProtocolFee: 2000, // 20%
        reserveFactor: 2000, // 20%
        supplyCap: 0, // Unlimited (facilitator-controlled)
        borrowCap: 500_000_000, // 500M jpyUBI
        debtCeiling: 0, // No isolation
        decimals: 18,
        borrowingEnabled: true, // Only borrowable asset
        flashLoanEnabled: false,
        borrowableIsolation: true
      });
  }
}

/**
 * @title NetworkAddresses
 * @notice External contract addresses per network
 */
library NetworkAddresses {
  // ══════════════════════════════════════════════════════════════════════════════
  // MAINNET
  // ══════════════════════════════════════════════════════════════════════════════

  struct MainnetAddresses {
    // Tokens
    address usdc;
    address usdt;
    address cbBtc;
    address link;
    address fet;
    address render;
    // Chainlink Oracles
    address jpyUsdFeed;
    address usdcUsdFeed;
    address usdtUsdFeed;
    address cbBtcUsdFeed;
    address linkUsdFeed;
    // DEX
    address uniV3Factory;
    address uniV3Router;
  }

  function getMainnetAddresses() internal pure returns (MainnetAddresses memory) {
    return
      MainnetAddresses({
        usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
        cbBtc: 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf,
        link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
        fet: 0xaea46A60368A7bD060eec7DF8CBa43b7EF41Ad85,
        render: 0x6De037ef9aD2725EB40118Bb1702EBb27e4Aeb24,
        jpyUsdFeed: 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3,
        usdcUsdFeed: 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6,
        usdtUsdFeed: 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D,
        cbBtcUsdFeed: 0x2665701293fCbEB223D11A08D826563EDcCE423A,
        linkUsdFeed: 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c,
        uniV3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984,
        uniV3Router: 0xE592427A0AEce92De3Edee1F18E0157C05861564
      });
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BASE
  // ══════════════════════════════════════════════════════════════════════════════

  struct BaseAddresses {
    address usdc;
    address usdt;
    address cbBtc;
    address link;
    address usdcUsdFeed;
    address usdtUsdFeed;
    address cbBtcUsdFeed;
    address linkUsdFeed;
    address uniV3Factory;
    address uniV3Router;
  }

  function getBaseAddresses() internal pure returns (BaseAddresses memory) {
    return
      BaseAddresses({
        usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
        usdt: 0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2,
        cbBtc: 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf,
        link: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196,
        usdcUsdFeed: 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B,
        usdtUsdFeed: 0xf19d560eB8d2ADf07BD6D13ed03e1D11215721F9,
        cbBtcUsdFeed: 0x07DA0E54543a844a80ABE69c8A12F22B3aA59f9D,
        linkUsdFeed: 0x17CAb8FE31E32f08326e5E27412894e49B0f9D65,
        uniV3Factory: 0x33128a8fC17869897dcE68Ed026d694621f6FDfD,
        uniV3Router: 0x2626664c2603336E57B271c5C0b26F421741e481
      });
  }
}
